require "test_helper"

class Generations::RateLimiterTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @anon = create(:anonymous_identity)
    @redis = Generations::RateLimiter.send(:redis)
    @test_id = SecureRandom.hex(8)
  end

  teardown do
    # Clean up only our test-specific keys
    ["rate_limit:user:#{@user.id}", "rate_limit:anon:#{@anon.id}",
     "rate_limit:ip:#{@test_id}"].each { |k| @redis.del(k) }
  end

  test "allows first request for user" do
    result = Generations::RateLimiter.check(user: @user)
    assert result[:allowed]
  end

  test "allows first request for anonymous" do
    result = Generations::RateLimiter.check(anonymous_identity: @anon)
    assert result[:allowed]
  end

  test "blocks after exceeding rate limit" do
    key = "rate_limit:user:#{@user.id}"
    max = Generations::RateLimiter::MAX_PER_MINUTE
    now = Time.current.to_f

    max.times do |i|
      @redis.zadd(key, now - i, "#{now - i}:#{SecureRandom.hex(4)}")
    end

    result = Generations::RateLimiter.check(user: @user)
    assert_not result[:allowed]
    assert_equal :rate_limited, result[:reason]
  end

  test "allows after window expires" do
    key = "rate_limit:user:#{@user.id}"
    max = Generations::RateLimiter::MAX_PER_MINUTE
    old_time = 2.minutes.ago.to_f

    max.times do |i|
      @redis.zadd(key, old_time - i, "#{old_time - i}:#{SecureRandom.hex(4)}")
    end

    result = Generations::RateLimiter.check(user: @user)
    assert result[:allowed]
  end

  test "record! adds timestamp" do
    Generations::RateLimiter.record!(user: @user)
    key = "rate_limit:user:#{@user.id}"
    assert_equal 1, @redis.zcard(key)
  end

  test "record! with IP adds IP timestamp" do
    ip = @test_id
    Generations::RateLimiter.record!(user: @user, ip: ip)
    assert_equal 1, @redis.zcard("rate_limit:user:#{@user.id}")
    assert_equal 1, @redis.zcard("rate_limit:ip:#{ip}")
    @redis.del("rate_limit:ip:#{ip}")
  end

  test "blocks by IP when too many requests" do
    ip = @test_id
    key = "rate_limit:ip:#{ip}"
    max = Generations::RateLimiter::MAX_PER_MINUTE_IP
    now = Time.current.to_f

    max.times do |i|
      @redis.zadd(key, now - i, "#{now - i}:#{SecureRandom.hex(4)}")
    end

    result = Generations::RateLimiter.check_ip(ip)
    assert_not result[:allowed]
    assert_equal :ip_rate_limited, result[:reason]
  end

  test "allows IP within limit" do
    result = Generations::RateLimiter.check_ip("unique-#{@test_id}")
    assert result[:allowed]
  end
end
