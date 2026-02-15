FactoryBot.define do
  factory :collection do
    name { Faker::Lorem.sentence(word_count: 3) }
    sequence(:slug) { |n| "collection-#{n}" }
    collection_type { "regular" }
    is_active { true }
    position { 0 }

    trait :limited do
      collection_type { "limited" }
      edition_size { 30 }
      stock_remaining { 30 }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
