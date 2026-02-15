module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    private

    def render_json(data, status: :ok)
      render json: data, status: status
    end
  end
end
