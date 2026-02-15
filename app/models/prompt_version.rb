class PromptVersion < ApplicationRecord
  belongs_to :prompt
  belongs_to :changed_by_user, class_name: "User", optional: true

  validates :text, presence: true
end
