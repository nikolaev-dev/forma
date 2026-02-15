require "net/http"
require "json"
require "uri"

module Payments
  class YookassaClient
    class PaymentError < StandardError; end

    BASE_URL = "https://api.yookassa.ru/v3"

    def initialize
      @shop_id = Rails.application.credentials.dig(:yookassa, :shop_id) || "test_shop"
      @secret_key = Rails.application.credentials.dig(:yookassa, :secret_key) || "test_key"
    end

    def create_order_payment(order, return_url:)
      create_payment(
        amount_cents: order.total_cents,
        currency: order.currency,
        description: "Заказ #{order.order_number}",
        return_url: return_url,
        metadata: { order_id: order.id }
      )
    end

    def create_payment(amount_cents:, currency: "RUB", description:, return_url:, idempotence_key: nil, metadata: {})
      idempotence_key ||= SecureRandom.uuid
      body = {
        amount: {
          value: format("%.2f", amount_cents / 100.0),
          currency: currency
        },
        confirmation: {
          type: "redirect",
          return_url: return_url
        },
        capture: true,
        description: description,
        metadata: metadata
      }

      response = post("/payments", body, idempotence_key: idempotence_key)

      {
        provider_payment_id: response["id"],
        status: response["status"],
        confirmation_url: response.dig("confirmation", "confirmation_url"),
        idempotence_key: idempotence_key,
        raw: response
      }
    end

    def get_payment(provider_payment_id)
      response = get("/payments/#{provider_payment_id}")

      {
        id: response["id"],
        status: response["status"],
        paid: response["paid"],
        amount: response["amount"],
        raw: response
      }
    end

    def create_refund(payment)
      body = {
        payment_id: payment.provider_payment_id,
        amount: {
          value: format("%.2f", payment.amount_cents / 100.0),
          currency: payment.currency
        }
      }

      response = post("/refunds", body, idempotence_key: SecureRandom.uuid)

      {
        id: response["id"],
        status: response["status"],
        raw: response
      }
    end

    private

    def post(path, body, idempotence_key: nil)
      uri = URI("#{BASE_URL}#{path}")
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(@shop_id, @secret_key)
      request.content_type = "application/json"
      request["Idempotence-Key"] = idempotence_key if idempotence_key
      request.body = body.to_json

      execute(uri, request)
    end

    def get(path)
      uri = URI("#{BASE_URL}#{path}")
      request = Net::HTTP::Get.new(uri)
      request.basic_auth(@shop_id, @secret_key)

      execute(uri, request)
    end

    def execute(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise PaymentError, "YooKassa HTTP #{response.code}: #{response.body}"
      end

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise PaymentError, "YooKassa connection error: #{e.message}"
    end
  end
end
