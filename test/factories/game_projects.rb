FactoryBot.define do
  factory :game_project do
    studio
    sequence(:title) { |n| "Game #{n}" }
  end
end
