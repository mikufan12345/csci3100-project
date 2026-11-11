# A Studio is a tenant: it owns its users and its game projects (and, through
# them, all rule modules, rulebook versions, sessions and feedback).
class Studio < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :game_projects, dependent: :destroy
end