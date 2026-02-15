class Style < ApplicationRecord
  include Hashid::Rails

  has_many :style_tags, dependent: :destroy
  has_many :tags, through: :style_tags

  has_one_attached :cover_image
  has_many_attached :gallery_images

  enum :status, { draft: "draft", published: "published", hidden: "hidden" }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :status, presence: true

  scope :published, -> { where(status: "published") }
  scope :ordered, -> { order(:position) }
  scope :popular, -> { order(popularity_score: :desc) }
  scope :editorial, -> { published.where("popularity_score >= ?", 4.0) }
end
