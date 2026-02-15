module Generations
  class LimitChecker
    DEFAULT_GUEST_LIMIT = 5
    DEFAULT_USER_LIMIT = 30

    Result = Struct.new(:allowed?, :reason, :limit, :used, keyword_init: true)

    # @param user [User, nil]
    # @param anonymous_identity [AnonymousIdentity, nil]
    # @return [Result]
    def self.call(user: nil, anonymous_identity: nil)
      new(user: user, anonymous_identity: anonymous_identity).call
    end

    def self.increment!(user: nil, anonymous_identity: nil)
      counter = UsageCounter.find_or_create_for(user: user, anonymous_identity: anonymous_identity)
      counter.increment!
    end

    def initialize(user: nil, anonymous_identity: nil)
      @user = user
      @anonymous_identity = anonymous_identity
    end

    def call
      # 1. Check active generation pass (users only)
      if @user && active_pass?
        return Result.new(allowed?: true, reason: :pass)
      end

      # 2. Check daily limit
      counter = find_counter
      used = counter&.generations_count || 0
      limit = daily_limit

      if used < limit
        Result.new(allowed?: true, reason: :within_limit, limit: limit, used: used)
      else
        Result.new(allowed?: false, reason: :daily_limit_reached, limit: limit, used: used)
      end
    end

    private

    def active_pass?
      GenerationPass.active_for(@user).exists?
    end

    def find_counter
      if @user
        UsageCounter.find_by(user: @user, period: Date.current)
      elsif @anonymous_identity
        UsageCounter.find_by(anonymous_identity: @anonymous_identity, period: Date.current)
      end
    end

    def daily_limit
      if @user
        setting = AppSetting["user_daily_limit"]
        setting&.fetch("value", DEFAULT_USER_LIMIT) || DEFAULT_USER_LIMIT
      else
        setting = AppSetting["guest_daily_limit"]
        setting&.fetch("value", DEFAULT_GUEST_LIMIT) || DEFAULT_GUEST_LIMIT
      end
    end
  end
end
