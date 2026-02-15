class TrainingBatchAnalysisJob < ApplicationJob
  queue_as :training

  def perform(training_batch_id)
    batch = TrainingBatch.find(training_batch_id)
    return unless batch.status_uploaded?

    batch.start_processing!

    batch.reference_images.pending_analysis.find_each do |ref|
      ref.start_analysis!

      # Enqueue analysis for both providers
      ReferenceImageAnalysisJob.perform_later(ref.id, "claude")
      ReferenceImageAnalysisJob.perform_later(ref.id, "openai")
    end
  end
end
