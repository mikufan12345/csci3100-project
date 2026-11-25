FactoryBot.define do
  factory :rulebook_version do
    game_project
    sequence(:version_number)
    status { 0 }

    trait :public do
      status { 1 }
    end

    trait :archived do
      status { 2 }
    end
  end
end
