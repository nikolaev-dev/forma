class CatalogItem < ApplicationRecord
  belongs_to :catalog_section
  belongs_to :item, polymorphic: true

  validates :item_type, presence: true
  validates :item_id, presence: true

  scope :ordered, -> { order(:position) }
  scope :pinned, -> { where(pinned: true) }
end
