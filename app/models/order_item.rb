class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :design
  belongs_to :notebook_sku
  belongs_to :filling

  TIERS = TierModifier::TIERS

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price_cents, presence: true
  validates :tier, inclusion: { in: TIERS }, allow_nil: true

  before_save :calculate_total

  private

  def calculate_total
    self.total_price_cents = unit_price_cents * quantity
  end
end
