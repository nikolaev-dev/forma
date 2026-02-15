module Payments
  class WebhooksController < ApplicationController
    skip_forgery_protection only: :yookassa

    def yookassa
      Payments::WebhookProcessor.call(params.to_unsafe_h)
      head :ok
    rescue => e
      Rails.logger.error("[YooKassa Webhook] Error: #{e.message}")
      head :ok
    end
  end
end
