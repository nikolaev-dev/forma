FactoryBot.define do
  factory :filling do
    name { "Клетка" }
    sequence(:slug) { |n| "grid-#{n}" }
    filling_type { "grid" }
    is_active { true }
  end
end
