require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:order_item).valid?
  end

  test "invalid without order" do
    assert_not build(:order_item, order: nil).valid?
  end

  test "invalid without design" do
    assert_not build(:order_item, design: nil).valid?
  end

  test "invalid without notebook_sku" do
    assert_not build(:order_item, notebook_sku: nil).valid?
  end

  test "invalid without filling" do
    assert_not build(:order_item, filling: nil).valid?
  end

  test "quantity must be positive" do
    assert_not build(:order_item, quantity: 0).valid?
    assert_not build(:order_item, quantity: -1).valid?
  end

  test "calculates total_price_cents before save" do
    item = build(:order_item, quantity: 3, unit_price_cents: 259900, total_price_cents: 0)
    item.save!
    assert_equal 779700, item.total_price_cents
  end

  test "recalculates total_price_cents on quantity change" do
    item = create(:order_item, quantity: 1, unit_price_cents: 259900)
    item.update!(quantity: 2)
    assert_equal 519800, item.total_price_cents
  end
end
