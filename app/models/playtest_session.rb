class PlaytestSession < ApplicationRecord
  belongs_to :user
  belongs_to :rulebook_version
end
