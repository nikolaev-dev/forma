class ReferenceImageAnalysisJob < ApplicationJob
  queue_as :training
  retry_on Training::AiAnalyzer::AnalysisError, wait: :polynomially_longer, attempts: 3

  # @param reference_image_id [Integer]
  # @param provider [String] "claude" or "openai"
  def perform(reference_image_id, provider)
    reference_image = ReferenceImage.find(reference_image_id)

    # Idempotency: skip if already analyzed for this provider
    analysis_field = "ai_analysis_#{provider}"
    return if reference_image.send(analysis_field).present? && reference_image.send(analysis_field) != {}

    # Download image data
    raise "No image attached" unless reference_image.original_image.attached?

    image_data = reference_image.original_image.download
    content_type = reference_image.original_image.content_type

    # Run AI analysis
    result = Training::AiAnalyzer.call(
      image_data: image_data,
      content_type: content_type,
      provider: provider
    )

    # Store result
    reference_image.update!(analysis_field => result)

    # If both providers have analyzed, mark as analyzed
    reference_image.reload
    claude_done = reference_image.ai_analysis_claude.present? && reference_image.ai_analysis_claude != {}
    openai_done = reference_image.ai_analysis_openai.present? && reference_image.ai_analysis_openai != {}

    if claude_done && openai_done && reference_image.status_analyzing?
      reference_image.complete_analysis!
    end
  end
end
