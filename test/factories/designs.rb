FactoryBot.define do
  factory :design do
    user
    title { Faker::Lorem.sentence(word_count: 4) }
    base_prompt { Faker::Lorem.paragraph }
    visibility { "private" }
    moderation_status { "ok" }

    trait :public do
      visibility { "public" }
    end

    trait :with_style do
      style
    end
  end
end
