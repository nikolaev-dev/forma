class TierModifier < ApplicationRecord
  TIERS = %w[core signature lux].freeze

  enum :tier, { core: "core", signature: "signature", lux: "lux" }

  validates :tier, presence: true, uniqueness: true
  validates :prompt_modifier, presence: true

  scope :ordered, -> { order(Arel.sql("CASE tier WHEN 'core' THEN 0 WHEN 'signature' THEN 1 WHEN 'lux' THEN 2 END")) }

  def self.for(tier)
    find_by!(tier: tier)
  end
end
