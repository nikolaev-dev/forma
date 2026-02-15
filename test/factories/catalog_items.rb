FactoryBot.define do
  factory :catalog_item do
    catalog_section
    association :item, factory: :style
  end
end
