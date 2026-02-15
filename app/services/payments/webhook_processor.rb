module Payments
  class WebhookProcessor
    def self.call(payload)
      new(payload).process
    end

    def initialize(payload)
      @payload = payload
      @event = payload["event"]
      @object = payload["object"]
    end

    def process
      provider_payment_id = @object["id"]
      new_status = @object["status"]

      payment = Payment.find_by(provider_payment_id: provider_payment_id)
      return unless payment

      # Idempotency: skip if already in target status
      return if payment.status == new_status

      payment.update!(
        status: new_status,
        raw: @object,
        captured_at: new_status == "succeeded" ? Time.current : payment.captured_at
      )

      update_payable(payment, new_status)
    end

    private

    def update_payable(payment, new_status)
      payable = payment.payable

      case payable
      when Order
        update_order(payable, new_status)
      when GenerationPass
        update_generation_pass(payable, new_status)
      end
    end

    def update_order(order, new_status)
      case new_status
      when "succeeded"
        order.pay! if order.status == "awaiting_payment"
        OrderFileGenerationJob.perform_later(order.id)
      when "canceled"
        order.cancel! if order.status == "awaiting_payment"
      end
    end

    def update_generation_pass(pass, new_status)
      case new_status
      when "canceled"
        pass.cancel_pass! if pass.status == "active"
      end
    end
  end
end
