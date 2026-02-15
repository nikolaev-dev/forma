class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :design

  validates :design_id, uniqueness: { scope: :user_id }
end
