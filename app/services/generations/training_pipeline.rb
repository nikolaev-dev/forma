module Generations
  class TrainingPipeline
    # Creates a Design + Generation with 3 tier variants from a curated ReferenceImage
    #
    # @param reference_image [ReferenceImage] must be in "curated" status
    # @param user [User] the admin who triggers generation
    # @param provider [String] generation provider name (default: "test")
    # @return [Generation] the created generation
    def self.call(reference_image:, user:, provider: "test")
      new(reference_image:, user:, provider:).call
    end

    def initialize(reference_image:, user:, provider:)
      @reference_image = reference_image
      @user = user
      @provider = provider
    end

    def call
      raise "ReferenceImage must be curated" unless @reference_image.status_curated?
      raise "ReferenceImage must have a curated_prompt" if @reference_image.curated_prompt.blank?

      design = create_design
      generation = create_generation(design)
      create_tier_variants(generation)

      @reference_image.mark_generated!(design: design)

      GenerationJob.perform_later(generation.id)

      generation
    end

    private

    def create_design
      Design.create!(
        user: @user,
        title: @reference_image.curated_prompt.truncate(100),
        base_prompt: @reference_image.curated_prompt,
        visibility: "private",
        moderation_status: "ok",
        collection: @reference_image.collection
      )
    end

    def create_generation(design)
      Generation.create!(
        design: design,
        user: @user,
        source: "training_pipeline",
        status: "created",
        provider: @provider
      )
    end

    def create_tier_variants(generation)
      TierModifier::TIERS.each do |tier|
        composed = TierPromptComposer.call(
          curated_prompt: @reference_image.curated_prompt,
          tier: tier
        )

        generation.generation_variants.create!(
          kind: "main",
          tier: tier,
          status: "created",
          composed_prompt: composed[:composed_prompt]
        )
      end
    end
  end
end
