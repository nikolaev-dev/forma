require "test_helper"

class UsageCounterTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @anon = create(:anonymous_identity)
  end

  test "valid for user" do
    counter = build(:usage_counter, user: @user, anonymous_identity: nil)
    assert counter.valid?
  end

  test "valid for anonymous identity" do
    counter = build(:usage_counter, user: nil, anonymous_identity: @anon)
    assert counter.valid?
  end

  test "requires period" do
    counter = build(:usage_counter, user: @user, period: nil)
    assert_not counter.valid?
  end

  test "requires either user or anonymous_identity" do
    counter = build(:usage_counter, user: nil, anonymous_identity: nil)
    assert_not counter.valid?
  end

  test "rejects both user and anonymous_identity" do
    counter = build(:usage_counter, user: @user, anonymous_identity: @anon)
    assert_not counter.valid?
  end

  test "default generations_count is 0" do
    counter = UsageCounter.new(user: @user, period: Date.current)
    assert_equal 0, counter.generations_count
  end

  test "unique constraint on user_id + period" do
    create(:usage_counter, user: @user, period: Date.current)
    duplicate = build(:usage_counter, user: @user, period: Date.current)
    assert_not duplicate.valid?
  end

  test "unique constraint on anonymous_identity_id + period" do
    create(:usage_counter, user: nil, anonymous_identity: @anon, period: Date.current)
    duplicate = build(:usage_counter, user: nil, anonymous_identity: @anon, period: Date.current)
    assert_not duplicate.valid?
  end

  test "allows same user on different days" do
    create(:usage_counter, user: @user, period: Date.current)
    counter = build(:usage_counter, user: @user, period: Date.yesterday)
    assert counter.valid?
  end

  # increment!
  test "increment! increases generations_count by 1" do
    counter = create(:usage_counter, user: @user, generations_count: 5)
    counter.increment!
    assert_equal 6, counter.reload.generations_count
  end

  # find_or_create_for
  test "find_or_create_for user creates counter if none exists" do
    counter = UsageCounter.find_or_create_for(user: @user)
    assert counter.persisted?
    assert_equal @user.id, counter.user_id
    assert_equal Date.current, counter.period
    assert_equal 0, counter.generations_count
  end

  test "find_or_create_for user finds existing counter" do
    existing = create(:usage_counter, user: @user, period: Date.current, generations_count: 3)
    counter = UsageCounter.find_or_create_for(user: @user)
    assert_equal existing.id, counter.id
    assert_equal 3, counter.generations_count
  end

  test "find_or_create_for anonymous creates counter" do
    counter = UsageCounter.find_or_create_for(anonymous_identity: @anon)
    assert counter.persisted?
    assert_equal @anon.id, counter.anonymous_identity_id
    assert_nil counter.user_id
  end
end
