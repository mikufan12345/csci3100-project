FactoryBot.define do
  factory :playtest_session do
    playtime_minutes { 45 }
    scenarios_completed { 2 }
    association :rulebook_version, :public

    after(:build) do |session|
      studio = session.rulebook_version.game_project.studio
      session.user ||= build(:user, studio: studio)
    end

    trait :too_short do
      playtime_minutes { 29 }
      scenarios_completed { 2 }
    end

    trait :too_few_scenarios do
      playtime_minutes { 45 }
      scenarios_completed { 1 }
    end
  end
end
