FactoryBot.define do
  factory :rule_module do
    game_project { nil }
    title { "MyString" }
    deprecated { 1 }
  end
end
