module Generations
  # Abstract interface for generation providers.
  # All providers must implement these methods.
  class ProviderInterface
    # Create a generation request and return a provider job ID.
    # @param request [Hash] { prompt:, tags:, style_preset:, seed:, quality:, policy_flags: }
    # @return [String] provider_job_id
    def create_generation(request)
      raise NotImplementedError
    end

    # Get the status of a generation job.
    # @param provider_job_id [String]
    # @return [String] "pending" | "running" | "succeeded" | "failed"
    def get_status(provider_job_id)
      raise NotImplementedError
    end

    # Fetch the result of a completed generation.
    # @param provider_job_id [String]
    # @return [Hash] { image_data: <binary>, content_type:, metadata: {} }
    def fetch_result(provider_job_id)
      raise NotImplementedError
    end

    # Cancel a generation job (optional).
    # @param provider_job_id [String]
    def cancel(provider_job_id)
      raise NotImplementedError
    end
  end
end
