# A GameProject is one game a studio is developing: its rule modules and
# rulebook versions live under it.
class GameProject < ApplicationRecord
  belongs_to :studio
  has_many :rule_modules, dependent: :destroy
  has_many :rulebook_versions, dependent: :destroy
end
