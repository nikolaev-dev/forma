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
      return unless payable.is_a?(Order)

      case new_status
      when "succeeded"
        payable.pay! if payable.status == "awaiting_payment"
        OrderFileGenerationJob.perform_later(payable.id)
      when "canceled"
        payable.cancel! if payable.status == "awaiting_payment"
      end
    end
  end
end
