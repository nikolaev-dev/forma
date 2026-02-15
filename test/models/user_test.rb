require "test_helper"

class UserTest < ActiveSupport::TestCase
  # --- Validations ---
  test "valid with factory defaults" do
    assert build(:user).valid?
  end

  test "invalid without role" do
    assert_not build(:user, role: nil).valid?
  end

  test "invalid without status" do
    assert_not build(:user, status: nil).valid?
  end

  test "invalid without locale" do
    assert_not build(:user, locale: nil).valid?
  end

  test "email uniqueness allows nil" do
    create(:user, email: nil)
    assert build(:user, email: nil).valid?
  end

  test "email uniqueness rejects duplicates" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "phone uniqueness allows nil" do
    create(:user, phone: nil)
    assert build(:user, phone: nil).valid?
  end

  # --- Enums are string, not integer ---
  test "role enum uses string values in DB" do
    user = create(:user, role: "admin")
    raw = User.connection.select_value("SELECT role FROM users WHERE id = #{user.id}")
    assert_equal "admin", raw
  end

  test "status enum uses string values in DB" do
    user = create(:user, status: "blocked")
    raw = User.connection.select_value("SELECT status FROM users WHERE id = #{user.id}")
    assert_equal "blocked", raw
  end

  test "role enum defines all expected values" do
    expected = %w[user creator moderator admin]
    assert_equal expected.sort, User.roles.keys.sort
  end

  # --- Associations ---
  test "has many oauth_identities" do
    user = create(:user)
    create(:oauth_identity, user: user, provider: "google")
    create(:oauth_identity, user: user, provider: "vk")
    assert_equal 2, user.oauth_identities.count
  end

  test "destroying user destroys oauth_identities" do
    user = create(:user)
    create(:oauth_identity, user: user)
    assert_difference "OauthIdentity.count", -1 do
      user.destroy!
    end
  end

  # --- HashID ---
  test "generates hashid from id" do
    user = create(:user)
    assert user.hashid.present?
    assert user.hashid.length >= 6
  end

  test "finds by hashid" do
    user = create(:user)
    found = User.find(user.hashid)
    assert_equal user.id, found.id
  end

  # --- Defaults ---
  test "default role is user" do
    assert_equal "user", User.new.role
  end

  test "default status is active" do
    assert_equal "active", User.new.status
  end

  test "default locale is ru" do
    assert_equal "ru", User.new.locale
  end
end
