class Collection < ApplicationRecord
  has_many :designs, dependent: :nullify

  has_one_attached :cover_image

  enum :collection_type, { regular: "regular", limited: "limited" }, prefix: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :collection_type, presence: true
  validates :edition_size, presence: true, numericality: { greater_than: 0 }, if: :collection_type_limited?
  validates :stock_remaining, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :limited_requires_edition_size

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position) }

  def decrement_stock!
    raise "Not a limited collection" unless collection_type_limited?
    raise "Out of stock" if stock_remaining.nil? || stock_remaining <= 0

    with_lock do
      decrement!(:stock_remaining)
    end
  end

  private

  def limited_requires_edition_size
    if collection_type_limited? && edition_size.blank?
      errors.add(:edition_size, "is required for limited collections")
    end
  end
end
