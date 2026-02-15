FactoryBot.define do
  factory :style do
    name { Faker::Lorem.unique.sentence(word_count: 2) }
    sequence(:slug) { |n| "style-#{n}" }
    status { "published" }
    generation_preset { { "style_prompt" => "test style prompt" } }

    trait :draft do
      status { "draft" }
    end

    trait :hidden do
      status { "hidden" }
    end
  end
end
