class GenerationPass < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :user, optional: true
  has_many :payments, as: :payable, dependent: :destroy

  enum :status, {
    active: "active",
    expired: "expired",
    canceled: "canceled"
  }, prefix: true

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  TRANSITIONS = {
    "active"   => %w[expired canceled],
    "expired"  => [],
    "canceled" => []
  }.freeze

  scope :active_for, ->(user) {
    where(user: user, status: "active")
      .where("starts_at <= ? AND ends_at > ?", Time.current, Time.current)
  }

  def currently_active?
    status == "active" && starts_at <= Time.current && ends_at > Time.current
  end

  def expire!
    transition_to!("expired")
  end

  def cancel_pass!
    transition_to!("canceled")
  end

  private

  def transition_to!(new_status)
    allowed = TRANSITIONS.fetch(status, [])
    raise InvalidTransition, "Cannot transition from #{status} to #{new_status}" unless allowed.include?(new_status)
    update!(status: new_status)
  end
end
