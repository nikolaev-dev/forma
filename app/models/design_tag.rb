class DesignTag < ApplicationRecord
  belongs_to :design
  belongs_to :tag

  enum :source, { user: "user", system: "system", admin: "admin", autotag: "autotag" }, prefix: true

  validates :tag_id, uniqueness: { scope: :design_id }
  validates :source, presence: true
end
