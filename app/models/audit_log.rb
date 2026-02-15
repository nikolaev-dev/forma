class AuditLog < ApplicationRecord
  belongs_to :actor_user, class_name: "User"
  belongs_to :record, polymorphic: true, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_record, ->(record) { where(record_type: record.class.name, record_id: record.id) }

  def self.log!(actor:, action:, record: nil, before: {}, after: {}, ip: nil)
    create!(
      actor_user: actor,
      action: action,
      record_type: record&.class&.name,
      record_id: record&.id,
      before: before,
      after: after,
      ip: ip
    )
  end
end
