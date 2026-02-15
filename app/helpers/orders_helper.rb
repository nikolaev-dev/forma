module OrdersHelper
  STATUS_LABELS = {
    "draft"            => "Черновик",
    "awaiting_payment" => "Ожидает оплаты",
    "paid"             => "Оплачен",
    "in_production"    => "В производстве",
    "shipped"          => "Отправлен",
    "delivered"        => "Доставлен",
    "canceled"         => "Отменён",
    "refunded"         => "Возврат"
  }.freeze

  STATUS_CLASSES = {
    "draft"            => "bg-gray-100 text-gray-600",
    "awaiting_payment" => "bg-yellow-100 text-yellow-700",
    "paid"             => "bg-green-100 text-green-700",
    "in_production"    => "bg-blue-100 text-blue-700",
    "shipped"          => "bg-purple-100 text-purple-700",
    "delivered"        => "bg-green-100 text-green-700",
    "canceled"         => "bg-red-100 text-red-600",
    "refunded"         => "bg-orange-100 text-orange-600"
  }.freeze

  def order_status_label(status)
    STATUS_LABELS[status] || status
  end

  def order_status_class(status)
    STATUS_CLASSES[status] || "bg-gray-100 text-gray-600"
  end

  FILLING_ICONS = {
    "grid"  => "&#9638;",
    "ruled" => "&#9776;",
    "dot"   => "&#8943;",
    "blank" => "&#9744;"
  }.freeze

  def filling_type_icon(filling_type)
    (FILLING_ICONS[filling_type] || "&#9635;").html_safe
  end
end
