module Orders
  class NumberGenerator
    def self.call
      year = Time.current.year
      last_order = Order.where("order_number LIKE ?", "FORMA-#{year}-%")
                        .order(order_number: :desc)
                        .pick(:order_number)

      seq = if last_order
        last_order.split("-").last.to_i + 1
      else
        1
      end

      format("FORMA-%d-%06d", year, seq)
    end
  end
end
