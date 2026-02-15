require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google] = nil
  end

  test "create signs in existing user via oauth" do
    user = create(:user, email: "test@example.com")
    create(:oauth_identity, user: user, provider: "google", uid: "123")

    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new(
      provider: "google", uid: "123",
      info: { email: "test@example.com", name: "Test User" },
      credentials: { token: "tok", refresh_token: nil, expires_at: nil }
    )

    post "/auth/google/callback"
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "create registers new user via oauth" do
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new(
      provider: "google", uid: "new-uid-456",
      info: { email: "newuser@example.com", name: "New User" },
      credentials: { token: "tok", refresh_token: nil, expires_at: nil }
    )

    assert_difference [ "User.count", "OauthIdentity.count" ], 1 do
      post "/auth/google/callback"
    end

    assert_redirected_to root_path
    user = User.find_by(email: "newuser@example.com")
    assert_equal "New User", user.name
  end

  test "create links oauth to existing user by email" do
    user = create(:user, email: "existing@example.com")

    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new(
      provider: "google", uid: "link-uid",
      info: { email: "existing@example.com", name: user.name },
      credentials: { token: "tok", refresh_token: nil, expires_at: nil }
    )

    assert_no_difference "User.count" do
      assert_difference "OauthIdentity.count", 1 do
        post "/auth/google/callback"
      end
    end
  end

  test "destroy logs out user" do
    user = create(:user)
    sign_in_as(user)

    delete logout_path
    assert_redirected_to root_path
  end

  test "failure redirects with error message" do
    get "/auth/failure", params: { message: "invalid_credentials" }
    assert_redirected_to root_path
    assert_equal "Ошибка авторизации: invalid_credentials", flash[:alert]
  end
end
