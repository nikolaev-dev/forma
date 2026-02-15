class DesignRating < ApplicationRecord
  belongs_to :design
  belongs_to :user, optional: true

  enum :source, { user: "user", admin: "admin" }, prefix: true

  validates :score, presence: true, inclusion: { in: 1..5 }
  validates :design_id, uniqueness: { scope: :user_id, conditions: -> { where(source: "user") } },
            if: -> { source == "user" && user_id.present? }

  def self.average_for(design)
    where(design: design).average(:score)&.to_f
  end
end
