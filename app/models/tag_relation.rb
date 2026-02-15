class TagRelation < ApplicationRecord
  belongs_to :from_tag, class_name: "Tag"
  belongs_to :to_tag, class_name: "Tag"

  enum :relation_type, {
    parent_of: "parent_of",
    related: "related",
    conflicts_with: "conflicts_with",
    discouraged_with: "discouraged_with"
  }

  validates :relation_type, presence: true
  validates :from_tag_id, uniqueness: { scope: [ :to_tag_id, :relation_type ] }
  validates :weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :no_self_relation

  private

  def no_self_relation
    errors.add(:to_tag_id, "не может совпадать с from_tag_id") if from_tag_id == to_tag_id
  end
end
