module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        orders_today: Order.where("created_at >= ?", Time.current.beginning_of_day).count,
        orders_paid: Order.where(status: "paid").count,
        orders_in_production: Order.where(status: "in_production").count,
        styles_count: Style.count,
        styles_published: Style.published.count,
        tags_count: Tag.count,
        designs_count: Design.count,
        generations_today: Generation.where("created_at >= ?", Time.current.beginning_of_day).count
      }
      @recent_orders = Order.order(created_at: :desc).limit(5)
      @recent_audit = AuditLog.recent.limit(10)
    end
  end
end
