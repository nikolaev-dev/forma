class GenerationVariant < ApplicationRecord
  belongs_to :generation

  has_one_attached :preview_image
  has_one_attached :mockup_image
  has_one_attached :hires_image

  enum :kind, { main: "main", mutation_a: "mutation_a", mutation_b: "mutation_b" }, prefix: true
  enum :status, {
    created: "created",
    queued: "queued",
    running: "running",
    succeeded: "succeeded",
    failed: "failed"
  }, prefix: true

  TIERS = TierModifier::TIERS

  validates :kind, presence: true
  validates :status, presence: true
  validates :composed_prompt, presence: true
  validates :tier, inclusion: { in: TIERS }, allow_nil: true
  validates :kind, uniqueness: { scope: [ :generation_id, :tier ] }

  def queue!(provider_job_id)
    update!(status: "queued", provider_job_id: provider_job_id)
  end

  def start!
    update!(status: "running")
  end

  def succeed!(metadata = {})
    update!(status: "succeeded", provider_metadata: metadata)
  end

  def fail!(code: nil, message: nil)
    update!(status: "failed", error_code: code, error_message: message)
  end

  def preview_thumb
    return nil unless preview_image.attached?
    preview_image.variant(resize_to_limit: [ 300, 400 ])
  end

  def preview_medium
    return nil unless preview_image.attached?
    preview_image.variant(resize_to_limit: [ 600, 800 ])
  end
end
