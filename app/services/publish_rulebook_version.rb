# Publishes one draft and archives the previous public version of that game.
#
# Inside the same transaction, in this order (Business Rule 2):
#   1. lock the game's versions,
#   2. deprecate the named modules and record their replacements,
#   3. stamp eligible feedback on OLDER versions as re_evaluation,
#   4. archive the previous public version,
#   5. make the draft public.
#
# The stamp runs while the older version is still public, which is why it is
# never blocked by the archived read-only freeze.
class PublishRulebookVersion
  def initialize(version:, deprecate_module_ids:, replacements:)
    @version = version
    @deprecate_module_ids = Array(deprecate_module_ids).map(&:to_i)
    @replacements = replacements || {}
  end

  def call
    published = false

    unless @version.status == RulebookVersion::STATUS_DRAFT
      @version.errors.add(:base, "only a draft version can be published")
      return false
    end
    unless valid_replacements?
      @version.errors.add(:base, "a replacement must name another module of this game")
      return false
    end

    RulebookVersion.transaction do
      game = @version.game_project
      game.rulebook_versions.lock.load

      affected_module_ids = @deprecate_module_ids +
                            @replacements.keys.map { |key| key.to_i }

      deprecate_modules(game, affected_module_ids)
      stamp_re_evaluation(game, affected_module_ids)

      game.rulebook_versions.where(status: RulebookVersion::STATUS_PUBLIC)
                            .where.not(id: @version.id)
                            .update_all(status: RulebookVersion::STATUS_ARCHIVED)

      published = @version.update(status: RulebookVersion::STATUS_PUBLIC)
      raise ActiveRecord::Rollback unless published
    end

    published
  end

  private

  # A replacement maps a module of this game to a DIFFERENT module of the
  # same game. Anything else (foreign id, missing id, self) refuses the
  # whole publish: `update_all` would otherwise write any integer past the
  # model's validations.
  def valid_replacements?
    game = @version.game_project
    @replacements.all? do |old_id, new_id|
      old = game.rule_modules.find_by(id: old_id.to_i)
      new = game.rule_modules.find_by(id: new_id.to_i)
      !old.nil? && !new.nil? && old.id != new.id
    end
  end

  def deprecate_modules(game, module_ids)
    return if module_ids.empty?

    game.rule_modules.where(id: module_ids)
                    .where(deprecated: false)
                    .update_all(deprecated: true)

    @replacements.each do |old_id, new_id|
      game.rule_modules.where(id: old_id.to_i)
                      .update_all(replaced_by_id: new_id.to_i)
    end
  end

  # Business Rule 2: feedback on the affected modules in versions older than
  # the one being published is stamped re_evaluation when it is still
  # unreviewed or a valid bug. Terminal verdicts, an existing stamp, and
  # everything the row carries (comments, severity, priority) stay put.
  def stamp_re_evaluation(game, module_ids)
    return if module_ids.empty?

    eligible = Feedback
              .joins(:rule_module, playtest_session: :rulebook_version)
              .where(rule_modules: { id: module_ids, game_project_id: game.id })
              .where(rulebook_versions: { version_number: 0...@version.version_number })
              .where(status: [Feedback::STATUS_UNREVIEWED, Feedback::STATUS_VALID_BUG])

    eligible.find_each do |row|
      row.update_column(:status, Feedback::STATUS_RE_EVALUATION)
    end
  end
end