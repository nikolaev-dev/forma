class TrainingBatch < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :created_by_user, class_name: "User"

  has_many :reference_images, dependent: :destroy

  enum :status, {
    uploaded: "uploaded",
    processing: "processing",
    completed: "completed"
  }, prefix: true

  validates :name, presence: true
  validates :status, presence: true

  TRANSITIONS = {
    "uploaded" => %w[processing],
    "processing" => %w[completed],
    "completed" => []
  }.freeze

  def start_processing!
    transition_to!("processing")
  end

  def complete!
    transition_to!("completed")
  end

  def update_images_count!
    update!(images_count: reference_images.count)
  end

  private

  def transition_to!(new_status)
    allowed = TRANSITIONS.fetch(status, [])
    raise InvalidTransition, "Cannot transition from #{status} to #{new_status}" unless allowed.include?(new_status)
    update!(status: new_status)
  end
end
