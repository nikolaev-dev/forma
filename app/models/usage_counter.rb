class UsageCounter < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :anonymous_identity, optional: true

  validates :period, presence: true
  validate :exactly_one_identity
  validates :user_id, uniqueness: { scope: :period, allow_nil: true }
  validates :anonymous_identity_id, uniqueness: { scope: :period, allow_nil: true }

  def increment!
    increment(:generations_count)
    save!
  end

  def self.find_or_create_for(user: nil, anonymous_identity: nil)
    if user
      find_or_create_by!(user: user, period: Date.current)
    elsif anonymous_identity
      find_or_create_by!(anonymous_identity: anonymous_identity, period: Date.current)
    else
      raise ArgumentError, "Either user or anonymous_identity required"
    end
  end

  private

  def exactly_one_identity
    if user_id.blank? && anonymous_identity_id.blank?
      errors.add(:base, "Either user or anonymous_identity is required")
    elsif user_id.present? && anonymous_identity_id.present?
      errors.add(:base, "Cannot have both user and anonymous_identity")
    end
  end
end
