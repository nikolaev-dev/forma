class Payment < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :payable, polymorphic: true

  enum :status, {
    created: "created",
    pending: "pending",
    succeeded: "succeeded",
    canceled: "canceled",
    failed: "failed",
    refunded: "refunded"
  }, prefix: true

  validates :amount_cents, presence: true
  validates :status, presence: true
  validates :provider, presence: true

  TRANSITIONS = {
    "created"   => %w[pending succeeded failed canceled],
    "pending"   => %w[succeeded failed canceled],
    "succeeded" => %w[refunded succeeded],
    "canceled"  => [],
    "failed"    => [],
    "refunded"  => []
  }.freeze

  def pend!
    transition_to!("pending")
  end

  def succeed!
    return if status == "succeeded"
    transition_to!("succeeded")
    update!(captured_at: Time.current) if captured_at.nil?
  end

  def fail!
    transition_to!("failed")
  end

  def cancel_payment!
    transition_to!("canceled")
  end

  def refund_payment!
    transition_to!("refunded")
  end

  private

  def transition_to!(new_status)
    allowed = TRANSITIONS.fetch(status, [])
    raise InvalidTransition, "Cannot transition from #{status} to #{new_status}" unless allowed.include?(new_status)
    update!(status: new_status)
  end
end
