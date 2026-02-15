FactoryBot.define do
  factory :catalog_section do
    name { Faker::Lorem.unique.sentence(word_count: 2) }
    sequence(:slug) { |n| "section-#{n}" }
    section_type { "editorial" }
  end
end
