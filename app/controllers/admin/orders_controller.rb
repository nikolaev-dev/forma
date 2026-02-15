module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [ :show, :change_status ]

    def index
      @orders = Order.order(created_at: :desc)
      @orders = @orders.where(status: params[:status]) if params[:status].present?
      @orders = @orders.where("order_number ILIKE :q OR customer_email ILIKE :q OR customer_phone ILIKE :q OR customer_name ILIKE :q",
                              q: "%#{params[:q]}%") if params[:q].present?
      @orders = @orders.where("created_at >= ?", Date.parse(params[:from])) if params[:from].present?
      @orders = @orders.where("created_at <= ?", Date.parse(params[:to]).end_of_day) if params[:to].present?
    end

    def show
      @order_items = @order.order_items.includes(:design, :notebook_sku, :filling)
      @payments = @order.payments.order(created_at: :desc)
      @order_files = @order.order_files.order(:file_type)
    end

    def change_status
      new_status = params[:new_status]
      before_status = @order.status
      tracking = params[:tracking_number]

      case new_status
      when "in_production" then @order.produce!
      when "shipped"
        @order.update!(tracking_number: tracking) if tracking.present?
        @order.ship!
      when "delivered"     then @order.deliver!
      when "canceled"      then @order.cancel!
      when "refunded"      then @order.refund!
      else
        redirect_to admin_order_path(@order), alert: "Недопустимый статус"
        return
      end

      audit!(action: "order.status_change", record: @order,
             before: { status: before_status },
             after: { status: new_status })
      redirect_to admin_order_path(@order), notice: "Статус изменён на #{helpers.order_status_label(new_status)}"
    end

    def export_csv
      orders = Order.order(created_at: :desc)
      orders = orders.where(status: params[:status]) if params[:status].present?

      csv_data = generate_csv(orders)
      send_data csv_data, filename: "orders-#{Date.current}.csv", type: "text/csv"
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def generate_csv(orders)
      require "csv"
      CSV.generate(headers: true) do |csv|
        csv << [ "Номер", "Статус", "Клиент", "Email", "Телефон", "Сумма (коп.)", "Дата" ]
        orders.find_each do |order|
          csv << [
            order.order_number,
            order.status,
            order.customer_name,
            order.customer_email,
            order.customer_phone,
            order.total_cents,
            order.created_at.strftime("%Y-%m-%d %H:%M")
          ]
        end
      end
    end
  end
end
