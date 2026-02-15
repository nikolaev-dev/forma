require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in_as(@admin)
    @order = create(:order, :paid, total_cents: 259900, customer_name: "Тест Клиент")
  end

  test "index lists orders" do
    get admin_orders_path
    assert_response :success
    assert_match @order.order_number, response.body
  end

  test "index filters by status" do
    get admin_orders_path(status: "paid")
    assert_response :success
    assert_match @order.order_number, response.body
  end

  test "index filters by search query" do
    get admin_orders_path(q: "Тест Клиент")
    assert_response :success
    assert_match @order.order_number, response.body
  end

  test "show renders order details" do
    get admin_order_path(@order)
    assert_response :success
    assert_match @order.order_number, response.body
    assert_match "Тест Клиент", response.body
  end

  test "change_status transitions order to in_production" do
    patch change_status_admin_order_path(@order), params: { new_status: "in_production" }
    assert_redirected_to admin_order_path(@order)
    assert_equal "in_production", @order.reload.status
    assert_equal "order.status_change", AuditLog.last.action
  end

  test "change_status with shipped adds tracking number" do
    @order.produce!
    patch change_status_admin_order_path(@order), params: { new_status: "shipped", tracking_number: "TRACK-123" }
    assert_redirected_to admin_order_path(@order)
    assert_equal "shipped", @order.reload.status
    assert_equal "TRACK-123", @order.tracking_number
  end

  test "export_csv returns CSV file" do
    get export_csv_admin_orders_path
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match @order.order_number, response.body
  end
end
