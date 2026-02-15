class OrdersController < ApplicationController
  before_action :set_order, only: %i[show filling set_filling sku set_sku checkout update pay confirmed]

  # GET /orders/new?design_id=X
  def new
    design = Design.find(params[:design_id])
    order = Order.create!(status: "draft")

    redirect_to filling_order_path(order, design_id: design.id)
  end

  # GET /orders/:id/filling (S8)
  def filling
    @fillings = Filling.active.order(:name)
    @design_id = params[:design_id]
  end

  # PATCH /orders/:id/set_filling
  def set_filling
    filling = Filling.find(params[:filling_id])
    design = Design.find(params[:design_id])

    # Create or update order item with selected filling
    item = @order.order_items.first_or_initialize
    item.design = design
    item.filling = filling
    item.notebook_sku ||= NotebookSku.active.order(:price_cents).first
    item.unit_price_cents = item.notebook_sku.price_cents
    item.save!

    redirect_to sku_order_path(@order)
  end

  # GET /orders/:id/sku (S9)
  def sku
    @skus = NotebookSku.active.order(:price_cents)
    @order_item = @order.order_items.first
  end

  # PATCH /orders/:id/set_sku
  def set_sku
    sku = NotebookSku.find(params[:notebook_sku_id])
    item = @order.order_items.first!
    item.update!(notebook_sku: sku, unit_price_cents: sku.price_cents)
    @order.recalculate_totals!

    redirect_to checkout_order_path(@order)
  end

  # GET /orders/:id/checkout (S10)
  def checkout
    @order_item = @order.order_items.includes(:design, :notebook_sku, :filling).first
  end

  # PATCH /orders/:id
  def update
    @order.update!(order_params)
    @order.recalculate_totals!
    @order.submit!

    redirect_to pay_order_path(@order)
  end

  # POST /orders/:id/pay
  def pay
    client = Payments::YookassaClient.new
    result = client.create_payment(@order, return_url: confirmed_order_url(@order))

    @order.payments.create!(
      provider: "yookassa",
      provider_payment_id: result[:provider_payment_id],
      status: result[:status] || "pending",
      amount_cents: @order.total_cents,
      currency: @order.currency,
      idempotence_key: result[:idempotence_key],
      confirmation_url: result[:confirmation_url],
      raw: result[:raw] || {}
    )

    redirect_to result[:confirmation_url], allow_other_host: true
  end

  # GET /orders/:id/confirmed (S12)
  def confirmed
  end

  # GET /orders/:id
  def show
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:customer_name, :customer_phone, :customer_email, :notes)
  end
end
