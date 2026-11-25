FactoryBot.define do
  factory :rule_module do
    game_project
    sequence(:title) { |n| "Module #{n}" }
    # Integer until the migration in docs/refined_proposal.md makes this a boolean.
    deprecated { 0 }
  end
end
