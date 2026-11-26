# A RulebookVersion is a published snapshot of a game's rulebook: the set of
# RuleModules in force at publish time (statuses: draft/public/archived, at
# most one public per game).
class RulebookVersion < ApplicationRecord
  # Version status (rulebook_versions.status, integer)
  STATUS_DRAFT    = 0
  STATUS_PUBLIC   = 1
  STATUS_ARCHIVED = 2

  belongs_to :game_project
  has_many :rulebook_inclusions, dependent: :destroy
  has_many :rule_modules, through: :rulebook_inclusions
  has_many :playtest_sessions, dependent: :destroy

  validates :summary, presence: true, if: -> { status == 1 }
  validate :one_public_version, if: -> { status == 1 }
  validate :freeze_summary_after_draft, on: :update

  private

  def one_public_version
    return if game_project.nil?

    others = game_project.rulebook_versions.where(status: STATUS_PUBLIC)
    others = others.where.not(id: id) if persisted?
    return unless others.exists?

    errors.add(:status, "already has a public version")
  end

  # A draft may still be edited. Public and archived summaries stay put.
  def freeze_summary_after_draft
    return unless will_save_change_to_summary?
    return if status_in_database.to_i == 0

    errors.add(:summary, "cannot change after the version leaves draft")
  end
end
