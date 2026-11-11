FactoryBot.define do
  factory :user do
    studio
    email { "user#{sequence}@example.com" }
    password { "password123" }
    role { User::PLAYTESTER }
  end

  factory :studio_admin, parent: :user do
    role { User::STUDIO_ADMIN }
  end

  factory :arbiter, parent: :user do
    role { User::ARBITER }
  end
end