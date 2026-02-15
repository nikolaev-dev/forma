FactoryBot.define do
  factory :notebook_sku do
    sequence(:code) { |n| "sku-#{n}" }
    name { "FORMA Base" }
    price_cents { 259900 }
    currency { "RUB" }
    is_active { true }

    trait :base do
      code { "base" }
      name { "FORMA Base" }
      price_cents { 259900 }
    end

    trait :pro do
      code { "pro" }
      name { "FORMA Pro" }
      price_cents { 319900 }
    end

    trait :elite do
      code { "elite" }
      name { "FORMA Elite" }
      price_cents { 899900 }
    end

    trait :core do
      code { "core" }
      name { "FORMA Core" }
      price_cents { 259900 }
    end

    trait :signature do
      code { "signature" }
      name { "FORMA Signature" }
      price_cents { 319900 }
    end

    trait :lux do
      code { "lux" }
      name { "FORMA Lux" }
      price_cents { 899900 }
    end
  end
end
