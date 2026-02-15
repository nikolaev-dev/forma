class NotebookSku < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(is_active: true) }
end
