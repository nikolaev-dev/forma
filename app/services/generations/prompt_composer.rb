module Generations
  class PromptComposer
    POLICY_SUFFIX = "no logos, no brand names, no copyrighted characters, no trademarks"

    # @param user_prompt [String] raw user input
    # @param style [Style, nil] selected style
    # @param tags [Array<Tag>] selected tags (public)
    # @param hidden_tags [Array<Tag>] hidden tags injected by system
    # @return [Hash] { composed_prompt:, tags_used:, hidden_tags_used:, policy_applied: }
    def self.call(user_prompt:, style: nil, tags: [], hidden_tags: [])
      new(user_prompt:, style:, tags:, hidden_tags:).call
    end

    def initialize(user_prompt:, style: nil, tags: [], hidden_tags: [])
      @user_prompt = user_prompt.to_s.strip
      @style = style
      @tags = tags
      @hidden_tags = hidden_tags
    end

    def call
      parts = []
      parts << style_prefix if @style
      parts << @user_prompt if @user_prompt.present?
      parts << tags_fragment if @tags.any?
      parts << hidden_tags_fragment if @hidden_tags.any?
      parts << POLICY_SUFFIX

      {
        composed_prompt: parts.join(", "),
        tags_used: @tags.map(&:slug),
        hidden_tags_used: @hidden_tags.map(&:slug),
        policy_applied: %w[no_logos brand_mood_only]
      }
    end

    private

    def style_prefix
      preset = @style.generation_preset
      preset["style_prompt"] || @style.name
    end

    def tags_fragment
      @tags.map(&:name).join(", ")
    end

    def hidden_tags_fragment
      @hidden_tags.map(&:name).join(", ")
    end
  end
end
