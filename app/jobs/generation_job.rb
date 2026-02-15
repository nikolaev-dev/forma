class GenerationJob < ApplicationJob
  queue_as :generation

  def perform(generation_id)
    generation = ::Generation.find(generation_id)
    return if generation.status_canceled?

    generation.queue!
    provider = resolve_provider(generation.provider)

    generation.generation_variants.each do |variant|
      process_variant(variant, provider)
    end

    generation.finish!
  rescue => e
    generation&.update!(
      status: "failed",
      error_code: e.class.name,
      error_message: e.message,
      finished_at: Time.current
    )
    raise
  end

  private

  def process_variant(variant, provider)
    request = {
      prompt: variant.composed_prompt,
      seed: variant.seed,
      quality: "preview"
    }

    provider_job_id = provider.create_generation(request)
    variant.queue!(provider_job_id)

    variant.start!
    variant.generation.start! if variant.generation.status_queued?

    result = poll_for_result(provider, provider_job_id)

    if result
      attach_image(variant, result)
      variant.succeed!(result[:metadata] || {})
    else
      variant.fail!(code: "timeout", message: "Provider did not return result in time")
    end
  rescue => e
    variant.fail!(code: e.class.name, message: e.message)
  end

  def poll_for_result(provider, provider_job_id, max_attempts: 60, interval: 2)
    max_attempts.times do
      status = provider.get_status(provider_job_id)

      case status
      when "succeeded"
        return provider.fetch_result(provider_job_id)
      when "failed"
        return nil
      else
        sleep(interval)
      end
    end
    nil
  end

  def attach_image(variant, result)
    return unless result[:image_data]

    extension = result[:content_type]&.split("/")&.last || "png"
    filename = "#{variant.generation_id}_#{variant.kind}.#{extension}"

    variant.preview_image.attach(
      io: StringIO.new(result[:image_data]),
      filename: filename,
      content_type: result[:content_type] || "image/png"
    )
  end

  def resolve_provider(provider_name)
    case provider_name
    when "test"
      ::Generations::Providers::TestProvider.new
    else
      # Future providers will be added here
      ::Generations::Providers::TestProvider.new
    end
  end
end
