class StyleTag < ApplicationRecord
  belongs_to :style
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :style_id }
end
