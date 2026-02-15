class CatalogSection < ApplicationRecord
  has_many :catalog_items, dependent: :destroy

  enum :section_type, {
    editorial: "editorial",
    popular: "popular",
    new: "new",
    drop: "drop",
    custom: "custom"
  }, prefix: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :section_type, presence: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position) }
end
