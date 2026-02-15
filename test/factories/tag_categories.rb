FactoryBot.define do
  factory :tag_category do
    name { Faker::Lorem.unique.word.capitalize }
    sequence(:slug) { |n| "category-#{n}" }
    position { 0 }
  end
end
