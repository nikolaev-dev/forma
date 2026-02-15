require "test_helper"

class GenerationPassTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "valid with all required fields" do
    pass = build(:generation_pass, user: @user)
    assert pass.valid?
  end

  test "requires starts_at" do
    pass = build(:generation_pass, starts_at: nil)
    assert_not pass.valid?
  end

  test "requires ends_at" do
    pass = build(:generation_pass, ends_at: nil)
    assert_not pass.valid?
  end

  test "requires price_cents to be positive" do
    pass = build(:generation_pass, price_cents: 0)
    assert_not pass.valid?
    pass.price_cents = -100
    assert_not pass.valid?
  end

  test "default status is active" do
    pass = create(:generation_pass, user: @user)
    assert_equal "active", pass.status
  end

  test "default price_cents is 10000" do
    pass = GenerationPass.new(user: @user, starts_at: Time.current, ends_at: 24.hours.from_now)
    assert_equal 10000, pass.price_cents
  end

  # State machine
  test "expire! transitions active to expired" do
    pass = create(:generation_pass, user: @user)
    pass.expire!
    assert_equal "expired", pass.status
  end

  test "cancel_pass! transitions active to canceled" do
    pass = create(:generation_pass, user: @user)
    pass.cancel_pass!
    assert_equal "canceled", pass.status
  end

  test "cannot expire already expired pass" do
    pass = create(:generation_pass, :expired, user: @user)
    assert_raises(GenerationPass::InvalidTransition) { pass.expire! }
  end

  test "cannot cancel expired pass" do
    pass = create(:generation_pass, :expired, user: @user)
    assert_raises(GenerationPass::InvalidTransition) { pass.cancel_pass! }
  end

  test "cannot cancel already canceled pass" do
    pass = create(:generation_pass, :canceled, user: @user)
    assert_raises(GenerationPass::InvalidTransition) { pass.cancel_pass! }
  end

  # Scopes
  test "scope active_for returns active passes covering current time" do
    active_pass = create(:generation_pass, user: @user, starts_at: 1.hour.ago, ends_at: 23.hours.from_now)
    _expired_time = create(:generation_pass, user: @user, starts_at: 2.days.ago, ends_at: 1.day.ago)
    _canceled = create(:generation_pass, :canceled, user: @user, starts_at: 1.hour.ago, ends_at: 23.hours.from_now)

    result = GenerationPass.active_for(@user)
    assert_includes result, active_pass
    assert_equal 1, result.count
  end

  test "active? checks status and time range" do
    pass = create(:generation_pass, user: @user, starts_at: 1.hour.ago, ends_at: 23.hours.from_now)
    assert pass.currently_active?

    expired_pass = create(:generation_pass, user: @user, starts_at: 2.days.ago, ends_at: 1.day.ago)
    assert_not expired_pass.currently_active?
  end

  # Payments
  test "has_many payments as payable" do
    pass = create(:generation_pass, user: @user)
    payment = create(:payment, payable: pass, amount_cents: 10000)
    assert_equal [payment], pass.payments.to_a
  end
end
