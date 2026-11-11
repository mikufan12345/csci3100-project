# A RulebookVersion is a published snapshot of a game's rulebook: the set of
# RuleModules in force at publish time (statuses: draft/public/archived, at
# most one public per game).
class RulebookVersion < ApplicationRecord
  belongs_to :game_project
end
