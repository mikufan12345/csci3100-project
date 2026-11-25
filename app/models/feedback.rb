class Feedback < ApplicationRecord
  belongs_to :playtest_session
  belongs_to :rule_module

  before_validation :assign_unreviewed_status, on: :create
  validate :session_meets_play_gate

  private

  def assign_unreviewed_status
    self.status = 0 if status.nil?
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
