class PlaytestSession < ApplicationRecord
  belongs_to :user
  belongs_to :rulebook_version
  has_many :feedbacks, dependent: :destroy

  validate :freeze_recorded_play, on: :update

  private

  # BR1: once feedback exists, the numbers that satisfied the gate stay put.
  def freeze_recorded_play
    return unless feedbacks.exists?

    if will_save_change_to_playtime_minutes?
      errors.add(:playtime_minutes, "is frozen once feedback has been submitted")
    end
    if will_save_change_to_scenarios_completed?
      errors.add(:scenarios_completed, "is frozen once feedback has been submitted")
    end
  end
end
