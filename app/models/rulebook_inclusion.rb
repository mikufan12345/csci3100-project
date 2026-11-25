class RulebookInclusion < ApplicationRecord
  belongs_to :rulebook_version
  belongs_to :rule_module
end
