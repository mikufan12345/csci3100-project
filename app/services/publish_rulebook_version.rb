# Publishes one draft and archives the previous public version of that game.
# Business Rule 2's deprecation, replacement, and re-evaluation stamp belong
# in this transaction before the archive. This slice does not apply them.
class PublishRulebookVersion
  def initialize(version:, deprecate_module_ids:, replacements:)
    @version = version
    @deprecate_module_ids = Array(deprecate_module_ids)
    @replacements = replacements || {}
  end

  def call
    published = false

    RulebookVersion.transaction do
      game = @version.game_project
      game.rulebook_versions.lock.load

      game.rulebook_versions.where(status: 1).where.not(id: @version.id).update_all(status: 2)

      published = @version.update(status: 1)
      raise ActiveRecord::Rollback unless published
    end

    published
  end
end
