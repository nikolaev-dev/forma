require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:payment).valid?
  end

  test "invalid without amount_cents" do
    assert_not build(:payment, amount_cents: nil).valid?
  end

  test "status enum uses string values" do
    payment = create(:payment, status: "pending")
    raw = Payment.connection.select_value("SELECT status FROM payments WHERE id = #{payment.id}")
    assert_equal "pending", raw
  end

  test "polymorphic payable association" do
    order = create(:order)
    payment = create(:payment, payable: order)
    assert_equal order, payment.payable
    assert_equal "Order", payment.payable_type
  end

  # --- State Machine ---

  test "pend! transitions created to pending" do
    payment = create(:payment, status: "created")
    payment.pend!
    assert_equal "pending", payment.status
  end

  test "succeed! transitions pending to succeeded" do
    payment = create(:payment, :pending)
    payment.succeed!
    assert_equal "succeeded", payment.status
    assert_not_nil payment.captured_at
  end

  test "succeed! transitions created to succeeded" do
    payment = create(:payment, status: "created")
    payment.succeed!
    assert_equal "succeeded", payment.status
  end

  test "fail! transitions pending to failed" do
    payment = create(:payment, :pending)
    payment.fail!
    assert_equal "failed", payment.status
  end

  test "cancel_payment! transitions pending to canceled" do
    payment = create(:payment, :pending)
    payment.cancel_payment!
    assert_equal "canceled", payment.status
  end

  test "refund_payment! transitions succeeded to refunded" do
    payment = create(:payment, :succeeded)
    payment.refund_payment!
    assert_equal "refunded", payment.status
  end

  test "idempotent — ignores same status transition" do
    payment = create(:payment, :succeeded)
    payment.succeed!
    assert_equal "succeeded", payment.status
  end
end
