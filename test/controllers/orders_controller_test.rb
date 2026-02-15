require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @design = create(:design)
    @generation = create(:generation, design: @design, status: "succeeded")
    @variant = create(:generation_variant, :main, :succeeded, generation: @generation)

    @filling_grid = create(:filling, name: "Клетка", slug: "grid", filling_type: "grid")
    @filling_ruled = create(:filling, name: "Линейка", slug: "ruled", filling_type: "ruled")

    @sku_base = create(:notebook_sku, :base)
    @sku_pro = create(:notebook_sku, :pro)
  end

  # --- filling (S8) ---

  test "filling renders filling selection" do
    get filling_order_path(create_draft_order)
    assert_response :success
    assert_match "Клетка", response.body
    assert_match "Линейка", response.body
  end

  # --- sku (S9) ---

  test "sku renders SKU selection" do
    order = create_draft_order
    create(:order_item, order: order, design: @design, notebook_sku: @sku_base,
           filling: @filling_grid, unit_price_cents: @sku_base.price_cents)

    get sku_order_path(order)
    assert_response :success
    assert_match "FORMA Base", response.body
    assert_match "FORMA Pro", response.body
  end

  # --- checkout (S10) ---

  test "checkout renders checkout form" do
    order = create_draft_order
    create(:order_item, order: order, design: @design, notebook_sku: @sku_base,
           filling: @filling_grid, unit_price_cents: @sku_base.price_cents)

    get checkout_order_path(order)
    assert_response :success
    assert_select "input[name='order[customer_name]']"
    assert_select "input[name='order[customer_phone]']"
    assert_select "input[name='order[customer_email]']"
  end

  # --- new (start order from design) ---

  test "new creates draft order and redirects to filling" do
    assert_difference "Order.count", 1 do
      get new_order_path(design_id: @design.id)
    end

    order = Order.last
    assert_equal "draft", order.status
    assert_redirected_to filling_order_path(order, design_id: @design.id)
  end

  # --- create (submit order) ---

  test "create updates order and transitions to awaiting_payment" do
    order = create_draft_order
    create(:order_item, order: order, design: @design, notebook_sku: @sku_base,
           filling: @filling_grid, unit_price_cents: @sku_base.price_cents)

    patch order_path(order), params: {
      order: {
        customer_name: "Иван Иванов",
        customer_phone: "+79001234567",
        customer_email: "ivan@example.com"
      }
    }

    order.reload
    assert_equal "awaiting_payment", order.status
    assert_equal "Иван Иванов", order.customer_name
    assert_redirected_to pay_order_path(order)
  end

  # --- confirmed (S12) ---

  test "confirmed renders order confirmation" do
    order = create(:order, :paid)

    get confirmed_order_path(order)
    assert_response :success
    assert_match order.order_number, response.body
  end

  # --- show ---

  test "show renders order details" do
    order = create(:order, :paid)

    get order_path(order)
    assert_response :success
    assert_match order.order_number, response.body
  end

  private

  def create_draft_order
    create(:order, status: "draft")
  end
end
