class TagSynonym < ApplicationRecord
  belongs_to :tag

  validates :phrase, presence: true
  validates :normalized, presence: true, uniqueness: true

  before_validation :set_normalized

  private

  def set_normalized
    self.normalized = phrase&.strip&.downcase&.gsub(/\s+/, " ")
  end
end
