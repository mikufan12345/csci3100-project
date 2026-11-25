FactoryBot.define do
  factory :studio do
    sequence(:name) { |n| "Studio #{n}" }
  end
end
