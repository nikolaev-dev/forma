FactoryBot.define do
  factory :generation_pass do
    user
    status { "active" }
    starts_at { Time.current }
    ends_at { 24.hours.from_now }
    price_cents { 10000 }
    currency { "RUB" }
    fair_use { {} }

    trait :expired do
      status { "expired" }
      starts_at { 2.days.ago }
      ends_at { 1.day.ago }
    end

    trait :canceled do
      status { "canceled" }
    end
  end
end
