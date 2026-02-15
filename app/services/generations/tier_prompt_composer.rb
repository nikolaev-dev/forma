module Generations
  class TierPromptComposer
    SCENE_SETUP = "Editorial product photograph of a premium hardcover notebook on a styled flat-lay surface, " \
                  "45-degree camera angle, soft diffused studio lighting, neutral background"

    POLICY_SUFFIX = "no logos, no brand names, no copyrighted characters, no trademarks"

    # @param curated_prompt [String] curated prompt from Training Pipeline
    # @param tier [String] "core", "signature", or "lux"
    # @return [Hash] { composed_prompt:, negative_prompt:, tier:, settings: }
    def self.call(curated_prompt:, tier:)
      new(curated_prompt:, tier:).call
    end

    def initialize(curated_prompt:, tier:)
      @curated_prompt = curated_prompt.to_s.strip
      @tier = tier
      @tier_modifier = TierModifier.for(tier)
    end

    def call
      {
        composed_prompt: build_prompt,
        negative_prompt: @tier_modifier.negative_prompt,
        tier: @tier,
        settings: @tier_modifier.settings
      }
    end

    private

    def build_prompt
      parts = [SCENE_SETUP]
      parts << @curated_prompt if @curated_prompt.present?
      parts << @tier_modifier.prompt_modifier
      parts << @tier_modifier.identity_elements if @tier_modifier.identity_elements.present?
      parts << POLICY_SUFFIX

      parts.join(", ")
    end
  end
end
