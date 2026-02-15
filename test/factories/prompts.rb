FactoryBot.define do
  factory :prompt do
    design
    current_text { Faker::Lorem.paragraph }
  end
end
