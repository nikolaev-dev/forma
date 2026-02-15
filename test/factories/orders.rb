FactoryBot.define do
  factory :order do
    sequence(:order_number) { |n| "FORMA-2026-#{n.to_s.rjust(6, '0')}" }
    sequence(:barcode_value) { |n| "FORMA-2026-#{n.to_s.rjust(6, '0')}" }
    status { "draft" }
    currency { "RUB" }

    trait :with_user do
      user
    end

    trait :awaiting_payment do
      status { "awaiting_payment" }
      customer_name { "Тест Тестов" }
      customer_phone { "+79001234567" }
      customer_email { "test@example.com" }
    end

    trait :paid do
      status { "paid" }
      customer_name { "Тест Тестов" }
      customer_phone { "+79001234567" }
      customer_email { "test@example.com" }
    end
  end
end
