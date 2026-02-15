require "test_helper"
require "net/http"

class Payments::YookassaClientTest < ActiveSupport::TestCase
  setup do
    @client = Payments::YookassaClient.new
    @order = create(:order, :awaiting_payment, total_cents: 259900)
  end

  test "create_payment sends POST to YooKassa and returns payment data" do
    response_body = {
      "id" => "pay_123",
      "status" => "pending",
      "confirmation" => { "confirmation_url" => "https://yookassa.ru/pay/123" }
    }.to_json

    stub_response = Net::HTTPOK.new("1.1", "200", "OK")
    stub_response.stubs(:body).returns(response_body)
    stub_response.stubs(:content_type).returns("application/json")

    Net::HTTP.any_instance.stubs(:request).returns(stub_response)

    result = @client.create_payment(@order, return_url: "https://forma.ru/orders/1/confirmed")

    assert_equal "pay_123", result[:provider_payment_id]
    assert_equal "pending", result[:status]
    assert_equal "https://yookassa.ru/pay/123", result[:confirmation_url]
  end

  test "get_payment sends GET to YooKassa" do
    response_body = {
      "id" => "pay_123",
      "status" => "succeeded",
      "paid" => true,
      "amount" => { "value" => "2599.00", "currency" => "RUB" }
    }.to_json

    stub_response = Net::HTTPOK.new("1.1", "200", "OK")
    stub_response.stubs(:body).returns(response_body)
    stub_response.stubs(:content_type).returns("application/json")

    Net::HTTP.any_instance.stubs(:request).returns(stub_response)

    result = @client.get_payment("pay_123")

    assert_equal "pay_123", result[:id]
    assert_equal "succeeded", result[:status]
  end

  test "create_refund sends POST to YooKassa refunds" do
    payment = create(:payment, :succeeded, payable: @order, amount_cents: 259900)

    response_body = {
      "id" => "refund_456",
      "status" => "succeeded",
      "payment_id" => payment.provider_payment_id
    }.to_json

    stub_response = Net::HTTPOK.new("1.1", "200", "OK")
    stub_response.stubs(:body).returns(response_body)
    stub_response.stubs(:content_type).returns("application/json")

    Net::HTTP.any_instance.stubs(:request).returns(stub_response)

    result = @client.create_refund(payment)

    assert_equal "refund_456", result[:id]
    assert_equal "succeeded", result[:status]
  end
end
