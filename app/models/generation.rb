class Generation < ApplicationRecord
  include Hashid::Rails

  belongs_to :design
  belongs_to :user, optional: true
  belongs_to :anonymous_identity, optional: true

  has_many :generation_variants, dependent: :destroy
  has_many :generation_selections, dependent: :destroy

  enum :source, {
    create: "create",
    refine: "refine",
    remix: "remix",
    admin_batch: "admin_batch"
  }, prefix: true

  enum :status, {
    created: "created",
    queued: "queued",
    running: "running",
    partial: "partial",
    succeeded: "succeeded",
    failed: "failed",
    canceled: "canceled"
  }, prefix: true

  validates :provider, presence: true
  validates :status, presence: true
  validates :source, presence: true

  scope :active, -> { where(status: %w[created queued running partial]) }
  scope :completed, -> { where(status: %w[succeeded partial]) }

  def queue!
    update!(status: "queued")
  end

  def start!
    update!(status: "running", started_at: Time.current)
  end

  def finish!
    variants = generation_variants.reload
    succeeded = variants.count { |v| v.status == "succeeded" }
    failed = variants.count { |v| v.status == "failed" }
    total = variants.size

    new_status = if succeeded == total
      "succeeded"
    elsif failed == total
      "failed"
    elsif succeeded > 0
      "partial"
    else
      "failed"
    end

    update!(status: new_status, finished_at: Time.current)
  end

  def cancel!
    update!(status: "canceled", finished_at: Time.current)
  end
end
