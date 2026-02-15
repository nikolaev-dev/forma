require "test_helper"

class Payments::WebhookProcessorTest < ActiveSupport::TestCase
  test "processes payment.succeeded webhook and updates payment + order" do
    order = create(:order, :awaiting_payment, total_cents: 259900)
    payment = create(:payment,
      payable: order,
      provider_payment_id: "pay_123",
      status: "pending",
      amount_cents: 259900
    )

    payload = {
      "event" => "payment.succeeded",
      "object" => {
        "id" => "pay_123",
        "status" => "succeeded",
        "paid" => true,
        "amount" => { "value" => "2599.00", "currency" => "RUB" },
        "captured_at" => "2026-02-15T12:00:00.000Z"
      }
    }

    Payments::WebhookProcessor.call(payload)

    payment.reload
    order.reload

    assert_equal "succeeded", payment.status
    assert_equal "paid", order.status
  end

  test "processes payment.canceled webhook" do
    order = create(:order, :awaiting_payment)
    payment = create(:payment,
      payable: order,
      provider_payment_id: "pay_456",
      status: "pending",
      amount_cents: 259900
    )

    payload = {
      "event" => "payment.canceled",
      "object" => {
        "id" => "pay_456",
        "status" => "canceled"
      }
    }

    Payments::WebhookProcessor.call(payload)

    payment.reload
    assert_equal "canceled", payment.status
  end

  test "idempotent — ignores already succeeded payment" do
    order = create(:order, :paid)
    payment = create(:payment,
      payable: order,
      provider_payment_id: "pay_789",
      status: "succeeded",
      amount_cents: 259900,
      captured_at: 1.hour.ago
    )

    payload = {
      "event" => "payment.succeeded",
      "object" => {
        "id" => "pay_789",
        "status" => "succeeded"
      }
    }

    assert_nothing_raised { Payments::WebhookProcessor.call(payload) }
    assert_equal "succeeded", payment.reload.status
  end

  test "ignores unknown provider_payment_id" do
    payload = {
      "event" => "payment.succeeded",
      "object" => {
        "id" => "unknown_id",
        "status" => "succeeded"
      }
    }

    assert_nothing_raised { Payments::WebhookProcessor.call(payload) }
  end
end
