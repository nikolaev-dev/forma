class Design < ApplicationRecord
  include Hashid::Rails

  belongs_to :user, optional: true
  belongs_to :source_design, class_name: "Design", optional: true
  belongs_to :style, optional: true

  has_many :remixes, class_name: "Design", foreign_key: :source_design_id, dependent: :nullify
  has_many :design_tags, dependent: :destroy
  has_many :tags, through: :design_tags
  has_many :generations, dependent: :destroy
  has_one :prompt, dependent: :destroy

  has_one_attached :hero_image
  has_one_attached :share_image

  enum :visibility, { private: "private", unlisted: "unlisted", public: "public" }, prefix: true
  enum :moderation_status, { ok: "ok", requires_review: "requires_review", blocked: "blocked" }, prefix: :moderation

  validates :visibility, presence: true
  validates :moderation_status, presence: true

  scope :visible, -> { where(visibility: %w[unlisted public]) }
  scope :published, -> { where(visibility: "public") }
  scope :moderated, -> { where(moderation_status: "ok") }

  # Full-text search
  scope :search, ->(query) {
    where("search_vector @@ plainto_tsquery('russian', ?)", query)
      .order(Arel.sql("ts_rank(search_vector, plainto_tsquery('russian', #{connection.quote(query)})) DESC"))
  }
end
