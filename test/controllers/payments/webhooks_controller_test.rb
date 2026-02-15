require "test_helper"

class Payments::WebhooksControllerTest < ActionDispatch::IntegrationTest
  test "yookassa webhook processes payment and returns 200" do
    order = create(:order, :awaiting_payment, total_cents: 259900)
    payment = create(:payment,
      payable: order,
      provider_payment_id: "pay_webhook_test",
      status: "pending",
      amount_cents: 259900
    )

    payload = {
      event: "payment.succeeded",
      object: {
        id: "pay_webhook_test",
        status: "succeeded",
        paid: true,
        amount: { value: "2599.00", currency: "RUB" }
      }
    }

    post payments_yookassa_webhook_path, params: payload, as: :json

    assert_response :ok
    assert_equal "succeeded", payment.reload.status
    assert_equal "paid", order.reload.status
  end

  test "yookassa webhook returns 200 for unknown payment" do
    payload = {
      event: "payment.succeeded",
      object: {
        id: "unknown_payment",
        status: "succeeded"
      }
    }

    post payments_yookassa_webhook_path, params: payload, as: :json
    assert_response :ok
  end

  test "yookassa webhook returns 200 even on processing error" do
    Payments::WebhookProcessor.stubs(:call).raises(StandardError.new("unexpected"))

    payload = {
      event: "payment.succeeded",
      object: { id: "pay_error", status: "succeeded" }
    }

    post payments_yookassa_webhook_path, params: payload, as: :json
    assert_response :ok
  end
end
