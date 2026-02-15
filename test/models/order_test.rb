require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:order).valid?
  end

  test "generates hashid" do
    order = create(:order)
    assert order.hashid.present?
  end

  test "status enum uses string values" do
    order = create(:order, status: "draft")
    raw = Order.connection.select_value("SELECT status FROM orders WHERE id = #{order.id}")
    assert_equal "draft", raw
  end

  test "order_number must be unique" do
    create(:order, order_number: "FORMA-2026-000001", barcode_value: "BC-001")
    assert_not build(:order, order_number: "FORMA-2026-000001", barcode_value: "BC-002").valid?
  end

  test "barcode_value must be unique" do
    create(:order, order_number: "FORMA-2026-000001", barcode_value: "BC-001")
    assert_not build(:order, order_number: "FORMA-2026-000002", barcode_value: "BC-001").valid?
  end

  # --- State Machine ---

  test "submit! transitions draft to awaiting_payment" do
    order = create(:order, status: "draft",
      customer_name: "Тест", customer_phone: "+79001234567", customer_email: "t@t.com")
    order.submit!
    assert_equal "awaiting_payment", order.status
  end

  test "submit! raises when not in draft" do
    order = create(:order, :awaiting_payment)
    assert_raises(Order::InvalidTransition) { order.submit! }
  end

  test "pay! transitions awaiting_payment to paid" do
    order = create(:order, :awaiting_payment)
    order.pay!
    assert_equal "paid", order.status
  end

  test "pay! raises when not in awaiting_payment" do
    order = create(:order, status: "draft")
    assert_raises(Order::InvalidTransition) { order.pay! }
  end

  test "produce! transitions paid to in_production" do
    order = create(:order, :paid)
    order.produce!
    assert_equal "in_production", order.status
  end

  test "ship! transitions in_production to shipped" do
    order = create(:order, :paid, status: "in_production")
    order.ship!
    assert_equal "shipped", order.status
  end

  test "deliver! transitions shipped to delivered" do
    order = create(:order, :paid, status: "shipped")
    order.deliver!
    assert_equal "delivered", order.status
  end

  test "cancel! transitions awaiting_payment to canceled" do
    order = create(:order, :awaiting_payment)
    order.cancel!
    assert_equal "canceled", order.status
  end

  test "cancel! transitions paid to canceled" do
    order = create(:order, :paid)
    order.cancel!
    assert_equal "canceled", order.status
  end

  test "cancel! raises when in_production" do
    order = create(:order, :paid, status: "in_production")
    assert_raises(Order::InvalidTransition) { order.cancel! }
  end

  test "refund! transitions paid to refunded" do
    order = create(:order, :paid)
    order.refund!
    assert_equal "refunded", order.status
  end

  # --- Auto-generation ---

  test "auto-generates order_number before validation on create" do
    order = Order.new(status: "draft")
    order.valid?
    assert order.order_number.present?
    assert_match(/\AFORMA-\d{4}-\d{6}\z/, order.order_number)
  end

  test "auto-generates barcode_value before validation on create" do
    order = Order.new(status: "draft")
    order.valid?
    assert order.barcode_value.present?
  end

  # --- Recalculate totals ---

  test "recalculate_totals! sums order items" do
    order = create(:order)
    sku = create(:notebook_sku, :base)
    filling = create(:filling)
    design = create(:design)

    create(:order_item, order: order, design: design, notebook_sku: sku,
           filling: filling, quantity: 2, unit_price_cents: 259900, total_price_cents: 519800)

    order.recalculate_totals!
    assert_equal 519800, order.subtotal_cents
    assert_equal 519800, order.total_cents
  end
end
