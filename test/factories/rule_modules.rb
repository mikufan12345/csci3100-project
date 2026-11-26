FactoryBot.define do
  factory :rule_module do
    game_project
    sequence(:title) { |n| "Module #{n}" }
    deprecated { false }
  end
end
