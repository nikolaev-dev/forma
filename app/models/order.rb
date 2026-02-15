class Order < ApplicationRecord
  include Hashid::Rails

  class InvalidTransition < StandardError; end

  belongs_to :user, optional: true
  belongs_to :anonymous_identity, optional: true

  has_many :order_items, dependent: :destroy
  has_many :payments, as: :payable, dependent: :destroy
  has_many :order_files, dependent: :destroy

  enum :status, {
    draft: "draft",
    awaiting_payment: "awaiting_payment",
    paid: "paid",
    in_production: "in_production",
    shipped: "shipped",
    delivered: "delivered",
    canceled: "canceled",
    refunded: "refunded"
  }, prefix: true

  validates :order_number, presence: true, uniqueness: true
  validates :barcode_value, presence: true, uniqueness: true
  validates :status, presence: true

  before_validation :generate_order_number, on: :create
  before_validation :generate_barcode_value, on: :create

  # --- State Machine ---

  TRANSITIONS = {
    "draft"            => %w[awaiting_payment canceled],
    "awaiting_payment" => %w[paid canceled],
    "paid"             => %w[in_production canceled refunded],
    "in_production"    => %w[shipped],
    "shipped"          => %w[delivered],
    "delivered"        => [],
    "canceled"         => [],
    "refunded"         => []
  }.freeze

  def submit!
    transition_to!("awaiting_payment")
  end

  def pay!
    transition_to!("paid")
  end

  def produce!
    transition_to!("in_production")
  end

  def ship!
    transition_to!("shipped")
  end

  def deliver!
    transition_to!("delivered")
  end

  def cancel!
    transition_to!("canceled")
  end

  def refund!
    transition_to!("refunded")
  end

  def recalculate_totals!
    self.subtotal_cents = order_items.sum(:total_price_cents)
    self.total_cents = subtotal_cents + shipping_cents
    save!
  end

  private

  def transition_to!(new_status)
    allowed = TRANSITIONS.fetch(status, [])
    raise InvalidTransition, "Cannot transition from #{status} to #{new_status}" unless allowed.include?(new_status)
    update!(status: new_status)
  end

  def generate_order_number
    return if order_number.present?
    year = Time.current.year
    seq = self.class.where("order_number LIKE ?", "FORMA-#{year}-%").count + 1
    self.order_number = format("FORMA-%d-%06d", year, seq)
  end

  def generate_barcode_value
    return if barcode_value.present?
    self.barcode_value = order_number
  end
end
