FactoryBot.define do
  factory :rulebook_version do
    game_project { nil }
    version_number { 1 }
    status { 1 }
  end
end
