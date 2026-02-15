FactoryBot.define do
  factory :payment do
    association :payable, factory: :order
    provider { "yookassa" }
    status { "created" }
    amount_cents { 259900 }
    currency { "RUB" }

    trait :pending do
      status { "pending" }
      provider_payment_id { SecureRandom.uuid }
    end

    trait :succeeded do
      status { "succeeded" }
      provider_payment_id { SecureRandom.uuid }
      captured_at { Time.current }
    end
  end
end
