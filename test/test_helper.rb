ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize(workers: :number_of_processors)
  end
end

module AdminIntegrationHelper
  def sign_in_as(user)
    # Set session directly via a test-only mechanism
    # In integration tests, we POST to the OmniAuth callback with a registered provider
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new(
      provider: "google",
      uid: user.id.to_s,
      info: { email: user.email, name: user.name },
      credentials: { token: "test_token", refresh_token: nil, expires_at: nil }
    )
    post "/auth/google/callback"
    OmniAuth.config.test_mode = false
  end
end

class ActionDispatch::IntegrationTest
  include AdminIntegrationHelper
end
