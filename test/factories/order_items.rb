FactoryBot.define do
  factory :order_item do
    order
    design
    notebook_sku
    filling
    quantity { 1 }
    unit_price_cents { 259900 }
    total_price_cents { 259900 }
  end
end
