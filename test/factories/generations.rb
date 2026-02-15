FactoryBot.define do
  factory :generation do
    design
    user
    source { "create" }
    status { "created" }
    provider { "test" }

    trait :with_variants do
      after(:create) do |generation|
        create(:generation_variant, :main, generation: generation)
        create(:generation_variant, :mutation_a, generation: generation)
        create(:generation_variant, :mutation_b, generation: generation)
      end
    end
  end
end
