FactoryBot.define do
  factory :generation_variant do
    generation
    kind { "main" }
    status { "created" }
    composed_prompt { Faker::Lorem.paragraph }

    trait :main do
      kind { "main" }
    end

    trait :mutation_a do
      kind { "mutation_a" }
      mutation_summary { "Добавили: тег" }
    end

    trait :mutation_b do
      kind { "mutation_b" }
      mutation_summary { "Добавили: другой тег" }
    end

    trait :succeeded do
      status { "succeeded" }
    end

    trait :failed do
      status { "failed" }
      error_code { "provider_error" }
      error_message { "Something went wrong" }
    end
  end
end
