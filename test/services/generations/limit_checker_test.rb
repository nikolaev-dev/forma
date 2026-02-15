require "test_helper"

class Generations::LimitCheckerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @anon = create(:anonymous_identity)

    # Configure limits via AppSetting
    AppSetting.set("guest_daily_limit", { "value" => 3 })
    AppSetting.set("user_daily_limit", { "value" => 20 })
  end

  # can_generate? for user with active pass
  test "user with active pass can always generate" do
    create(:generation_pass, user: @user, starts_at: 1.hour.ago, ends_at: 23.hours.from_now)
    create(:usage_counter, user: @user, generations_count: 100)

    result = Generations::LimitChecker.call(user: @user)
    assert result.allowed?
    assert_equal :pass, result.reason
  end

  # can_generate? for user within limit
  test "user within daily limit can generate" do
    create(:usage_counter, user: @user, generations_count: 19)

    result = Generations::LimitChecker.call(user: @user)
    assert result.allowed?
    assert_equal :within_limit, result.reason
  end

  # can_generate? for user at limit
  test "user at daily limit cannot generate" do
    create(:usage_counter, user: @user, generations_count: 20)

    result = Generations::LimitChecker.call(user: @user)
    assert_not result.allowed?
    assert_equal :daily_limit_reached, result.reason
    assert_equal 20, result.limit
    assert_equal 20, result.used
  end

  # can_generate? for user over limit
  test "user over daily limit cannot generate" do
    create(:usage_counter, user: @user, generations_count: 25)

    result = Generations::LimitChecker.call(user: @user)
    assert_not result.allowed?
  end

  # can_generate? for user with no counter yet
  test "user with no counter can generate" do
    result = Generations::LimitChecker.call(user: @user)
    assert result.allowed?
    assert_equal :within_limit, result.reason
  end

  # can_generate? for anonymous within limit
  test "anonymous within limit can generate" do
    create(:usage_counter, user: nil, anonymous_identity: @anon, generations_count: 2)

    result = Generations::LimitChecker.call(anonymous_identity: @anon)
    assert result.allowed?
  end

  # can_generate? for anonymous at limit
  test "anonymous at limit cannot generate" do
    create(:usage_counter, user: nil, anonymous_identity: @anon, generations_count: 3)

    result = Generations::LimitChecker.call(anonymous_identity: @anon)
    assert_not result.allowed?
    assert_equal :daily_limit_reached, result.reason
    assert_equal 3, result.limit
  end

  # can_generate? for anonymous with no counter
  test "anonymous with no counter can generate" do
    result = Generations::LimitChecker.call(anonymous_identity: @anon)
    assert result.allowed?
  end

  # increment!
  test "increment! increases counter for user" do
    Generations::LimitChecker.increment!(user: @user)
    counter = UsageCounter.find_by(user: @user, period: Date.current)
    assert_equal 1, counter.generations_count
  end

  test "increment! increases existing counter" do
    create(:usage_counter, user: @user, generations_count: 5)
    Generations::LimitChecker.increment!(user: @user)
    counter = UsageCounter.find_by(user: @user, period: Date.current)
    assert_equal 6, counter.generations_count
  end

  test "increment! for anonymous identity" do
    Generations::LimitChecker.increment!(anonymous_identity: @anon)
    counter = UsageCounter.find_by(anonymous_identity: @anon, period: Date.current)
    assert_equal 1, counter.generations_count
  end

  # Default limits when settings not configured
  test "uses default guest limit when setting missing" do
    AppSetting.find_by(key: "guest_daily_limit")&.destroy
    create(:usage_counter, user: nil, anonymous_identity: @anon, generations_count: 5)

    result = Generations::LimitChecker.call(anonymous_identity: @anon)
    assert_not result.allowed?
    assert_equal 5, result.limit
  end

  test "uses default user limit when setting missing" do
    AppSetting.find_by(key: "user_daily_limit")&.destroy
    create(:usage_counter, user: @user, generations_count: 30)

    result = Generations::LimitChecker.call(user: @user)
    assert_not result.allowed?
    assert_equal 30, result.limit
  end

  # Expired pass doesn't grant access
  test "expired pass does not grant unlimited access" do
    create(:generation_pass, :expired, user: @user)
    create(:usage_counter, user: @user, generations_count: 20)

    result = Generations::LimitChecker.call(user: @user)
    assert_not result.allowed?
  end

  # Canceled pass doesn't grant access
  test "canceled pass does not grant unlimited access" do
    create(:generation_pass, :canceled, user: @user)
    create(:usage_counter, user: @user, generations_count: 20)

    result = Generations::LimitChecker.call(user: @user)
    assert_not result.allowed?
  end
end
