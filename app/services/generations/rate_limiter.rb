module Generations
  class RateLimiter
    MAX_PER_MINUTE = 5
    MAX_PER_MINUTE_IP = 3
    WINDOW_SECONDS = 60

    # Check rate limit for user or anonymous identity
    # @return [Hash] { allowed: bool, reason: symbol|nil }
    def self.check(user: nil, anonymous_identity: nil)
      key = if user
        "rate_limit:user:#{user.id}"
      elsif anonymous_identity
        "rate_limit:anon:#{anonymous_identity.id}"
      else
        return { allowed: true }
      end

      check_key(key, MAX_PER_MINUTE, :rate_limited)
    end

    # Check IP-based rate limit (anti-abuse for guests)
    def self.check_ip(ip)
      key = "rate_limit:ip:#{ip}"
      check_key(key, MAX_PER_MINUTE_IP, :ip_rate_limited)
    end

    # Record a generation request
    def self.record!(user: nil, anonymous_identity: nil, ip: nil)
      now = Time.current.to_f

      if user
        push_timestamp("rate_limit:user:#{user.id}", now)
      elsif anonymous_identity
        push_timestamp("rate_limit:anon:#{anonymous_identity.id}", now)
      end

      push_timestamp("rate_limit:ip:#{ip}", now) if ip
    end

    def self.redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    end

    private_class_method :redis

    def self.check_key(key, max, reason)
      now = Time.current.to_f
      window_start = now - WINDOW_SECONDS

      # Remove old entries
      redis.zremrangebyscore(key, "-inf", window_start)

      count = redis.zcard(key)
      if count >= max
        { allowed: false, reason: reason }
      else
        { allowed: true }
      end
    end

    private_class_method :check_key

    def self.push_timestamp(key, timestamp)
      redis.zadd(key, timestamp, "#{timestamp}:#{SecureRandom.hex(4)}")
      redis.expire(key, WINDOW_SECONDS + 10)
    end

    private_class_method :push_timestamp
  end
end
