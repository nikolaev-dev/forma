FactoryBot.define do
  factory :training_batch do
    name { "Партия #{Faker::Number.number(digits: 4)}" }
    status { "uploaded" }
    association :created_by_user, factory: :user
  end
end
