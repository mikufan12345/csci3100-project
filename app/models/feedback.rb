class Feedback < ApplicationRecord
  belongs_to :playtest_session
  belongs_to :rule_module

  # Omitted severity is low. An explicit nil still fails inclusion, which is
  # what "requires a severity" asserts.
  attribute :severity, :integer, default: 0

  validates :comments, presence: true
  validates :severity, inclusion: { in: [0, 1, 2] }

  before_validation :assign_unreviewed_status, on: :create
  validate :session_meets_play_gate
  validate :module_included_in_version
  validate :freeze_comments, on: :update

  private

  def assign_unreviewed_status
    self.status = 0 if status.nil?
  end

  def module_included_in_version
    version = playtest_session&.rulebook_version
    return if version.nil? || rule_module.nil?
    return if version.rule_modules.exists?(id: rule_module.id)

    errors.add(:rule_module, "is not in this rulebook version")
  end

  # Submitted comments stay byte-for-byte. A later save may still change
  # other columns; this slice does not decide which of those writes succeed.
  def freeze_comments
    return unless will_save_change_to_comments?

    errors.add(:comments, "cannot change after submission")
  end

  # BR1: the session itself may be short. Feedback may not.
  def session_meets_play_gate
    played = playtest_session
    return if played.nil?

    if played.playtime_minutes.to_i < 30
      errors.add(:base, "Playtime must be at least 30 minutes.")
    end
    if played.scenarios_completed.to_i < 2
      errors.add(:base, "At least 2 scenarios must be completed.")
    end
  end
end
