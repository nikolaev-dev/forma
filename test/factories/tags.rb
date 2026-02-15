FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.unique.word.capitalize }
    sequence(:slug) { |n| "tag-#{n}" }
    tag_category
    visibility { "public" }
    kind { "generic" }
    weight { 1.0 }

    trait :hidden do
      visibility { "hidden" }
    end

    trait :banned do
      is_banned { true }
      banned_reason { "Нарушение правил" }
    end

    trait :brand_mood do
      kind { "brand_mood" }
    end
  end
end
