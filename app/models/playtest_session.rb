class PlaytestSession < ApplicationRecord
  belongs_to :user
  belongs_to :rulebook_version
  has_many :feedbacks, dependent: :destroy

  validate :public_version_in_the_players_studio
  validate :freeze_recorded_play, on: :update

  private

  # Story 2: a session is logged against the player's own public rulebook.
  def public_version_in_the_players_studio
    version = rulebook_version
    return if version.nil?

    unless version.status == 1
      errors.add(:rulebook_version, "must be the public rulebook")
    end

    game_studio_id = version.game_project&.studio_id
    return if user.nil? || game_studio_id.nil?
    return if user.studio_id == game_studio_id

    errors.add(:rulebook_version, "belongs to another studio")
  end

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
