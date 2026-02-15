class ReferenceImage < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :training_batch, counter_cache: :images_count
  belongs_to :collection, optional: true
  belongs_to :design, optional: true

  has_one_attached :original_image

  enum :status, {
    uploaded: "uploaded",
    analyzing: "analyzing",
    analyzed: "analyzed",
    curated: "curated",
    generated: "generated",
    published: "published",
    rejected: "rejected"
  }, prefix: true

  validates :status, presence: true
  validates :selected_provider, inclusion: { in: %w[claude openai] }, allow_nil: true

  scope :pending_analysis, -> { where(status: "uploaded") }
  scope :pending_curation, -> { where(status: "analyzed") }
  scope :pending_generation, -> { where(status: "curated") }

  TRANSITIONS = {
    "uploaded" => %w[analyzing],
    "analyzing" => %w[analyzed],
    "analyzed" => %w[curated rejected],
    "curated" => %w[generated rejected],
    "generated" => %w[published rejected],
    "published" => [],
    "rejected" => []
  }.freeze

  def start_analysis!
    transition_to!("analyzing")
  end

  def complete_analysis!
    transition_to!("analyzed")
  end

  def curate!(prompt:, provider: nil, collection: nil, notes: nil)
    transaction do
      self.curated_prompt = prompt
      self.selected_provider = provider if provider
      self.collection = collection if collection
      self.curator_notes = notes if notes
      transition_to!("curated")
    end
  end

  def mark_generated!(design:)
    self.design = design
    transition_to!("generated")
  end

  def publish!
    transition_to!("published")
  end

  def reject!(notes: nil)
    self.curator_notes = notes if notes
    allowed = TRANSITIONS.fetch(status, [])
    raise InvalidTransition, "Cannot transition from #{status} to rejected" unless allowed.include?("rejected")
    update!(status: "rejected", curator_notes: curator_notes)
  end

  def best_ai_prompt
    case selected_provider
    when "claude"
      ai_analysis_claude.dig("base_prompt")
    when "openai"
      ai_analysis_openai.dig("base_prompt")
    else
      ai_analysis_claude.dig("base_prompt") || ai_analysis_openai.dig("base_prompt")
    end
  end

  private

  def transition_to!(new_status)
    allowed = TRANSITIONS.fetch(status, [])
    raise InvalidTransition, "Cannot transition from #{status} to #{new_status}" unless allowed.include?(new_status)
    update!(status: new_status)
  end
end
