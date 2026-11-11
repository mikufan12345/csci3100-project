# A RuleModule is a named section/chapter of a game's rulebook (e.g. "Combat",
# "Magic") — the unit players give feedback about and designers revise or
# deprecate when publishing a new RulebookVersion. 
class RuleModule < ApplicationRecord
  belongs_to :game_project
end
