FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    role { "user" }
    status { "active" }
    locale { "ru" }

    trait :admin do
      role { "admin" }
    end

    trait :creator do
      role { "creator" }
    end

    trait :blocked do
      status { "blocked" }
    end
  end
end
