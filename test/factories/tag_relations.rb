FactoryBot.define do
  factory :tag_relation do
    association :from_tag, factory: :tag
    association :to_tag, factory: :tag
    relation_type { "related" }
    weight { 1.0 }
  end
end
