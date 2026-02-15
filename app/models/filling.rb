class Filling < ApplicationRecord
  has_one_attached :preview_spread_image

  enum :filling_type, {
    grid: "grid",
    ruled: "ruled",
    dot: "dot",
    blank: "blank",
    planner_weekly: "planner_weekly",
    planner_daily: "planner_daily",
    dated: "dated"
  }, prefix: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :filling_type, presence: true

  scope :active, -> { where(is_active: true) }
end
