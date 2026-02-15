class Prompt < ApplicationRecord
  belongs_to :design

  has_many :prompt_versions, dependent: :destroy

  validates :current_text, presence: true

  def update_text!(new_text, user: nil, reason: nil, diff_summary: nil)
    transaction do
      prompt_versions.create!(
        text: new_text,
        changed_by_user: user,
        change_reason: reason,
        diff_summary: diff_summary
      )
      update!(current_text: new_text)
    end
  end
end
