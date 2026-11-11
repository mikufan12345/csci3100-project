FactoryBot.define do
  factory :feedback do
    playtest_session { nil }
    rule_module { nil }
    status { 1 }
    comments { "MyText" }
  end
end
