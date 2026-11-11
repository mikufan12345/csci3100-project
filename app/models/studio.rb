class Studio < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :game_projects, dependent: :destroy
end