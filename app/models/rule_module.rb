# A RuleModule is a named section/chapter of a game's rulebook (e.g. "Combat",
# "Magic") — the unit players give feedback about and designers revise or
# deprecate when publishing a new RulebookVersion. 
class RuleModule < ApplicationRecord
  belongs_to :game_project
  has_many :rulebook_inclusions, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
end
