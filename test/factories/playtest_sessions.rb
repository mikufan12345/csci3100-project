FactoryBot.define do
  factory :playtest_session do
    user { nil }
    rulebook_version { nil }
    playtime_minutes { 1 }
    scenarios_completed { 1 }
  end
end
