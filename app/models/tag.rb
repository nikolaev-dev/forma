class Tag < ApplicationRecord
  belongs_to :tag_category

  has_many :tag_synonyms, dependent: :destroy
  has_many :outgoing_relations, class_name: "TagRelation", foreign_key: :from_tag_id, dependent: :destroy
  has_many :incoming_relations, class_name: "TagRelation", foreign_key: :to_tag_id, dependent: :destroy
  has_many :style_tags, dependent: :destroy
  has_many :styles, through: :style_tags

  enum :visibility, { public: "public", hidden: "hidden" }, prefix: true
  enum :kind, { generic: "generic", brand_mood: "brand_mood" }, prefix: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :weight, numericality: { greater_than_or_equal_to: 0 }

  scope :visible, -> { where(visibility: "public") }
  scope :not_banned, -> { where(is_banned: false) }
  scope :available, -> { visible.not_banned }

  # Trigram search for autocomplete
  scope :search_by_name, ->(query) {
    where("name % ?", query).order(Arel.sql("similarity(name, #{connection.quote(query)}) DESC"))
  }
end
