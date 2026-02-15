module Payments
  class WebhooksController < ApplicationController
    skip_forgery_protection only: :yookassa

    def yookassa
      Payments::WebhookProcessor.call(params.to_unsafe_h)
      head :ok
    end
  end
end
