require "test_helper"

class OauthIdentityTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:oauth_identity).valid?
  end

  test "invalid without provider" do
    assert_not build(:oauth_identity, provider: nil).valid?
  end

  test "invalid without uid" do
    assert_not build(:oauth_identity, uid: nil).valid?
  end

  test "invalid without user" do
    assert_not build(:oauth_identity, user: nil).valid?
  end

  test "uid uniqueness scoped to provider" do
    create(:oauth_identity, provider: "google", uid: "123")
    assert_not build(:oauth_identity, provider: "google", uid: "123").valid?
  end

  test "same uid different provider is valid" do
    create(:oauth_identity, provider: "google", uid: "123")
    assert build(:oauth_identity, provider: "vk", uid: "123").valid?
  end

  test "provider enum uses string values in DB" do
    identity = create(:oauth_identity, provider: "vk")
    raw = OauthIdentity.connection.select_value(
      "SELECT provider FROM oauth_identities WHERE id = #{identity.id}"
    )
    assert_equal "vk", raw
  end

  test "encrypts access_token in DB" do
    identity = create(:oauth_identity, access_token: "secret_token_123")
    raw = OauthIdentity.connection.select_value(
      "SELECT access_token FROM oauth_identities WHERE id = #{identity.id}"
    )
    assert_not_equal "secret_token_123", raw
    assert_equal "secret_token_123", identity.access_token
  end

  test "encrypts refresh_token in DB" do
    identity = create(:oauth_identity, refresh_token: "refresh_secret")
    raw = OauthIdentity.connection.select_value(
      "SELECT refresh_token FROM oauth_identities WHERE id = #{identity.id}"
    )
    assert_not_equal "refresh_secret", raw
    assert_equal "refresh_secret", identity.refresh_token
  end
end
