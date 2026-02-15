module Generations
  class Pipeline
    # Orchestrates the full generation pipeline:
    # 1. Create Design + Prompt
    # 2. Create Generation + 3 Variants (main + 2 mutations)
    # 3. Enqueue GenerationJob
    #
    # @param user_prompt [String]
    # @param style [Style, nil]
    # @param tags [Array<Tag>]
    # @param user [User, nil]
    # @param anonymous_identity [AnonymousIdentity, nil]
    # @param source [String] "create" | "refine" | "remix"
    # @param design [Design, nil] existing design for refine/remix
    # @return [Generation]
    def self.call(**args)
      new(**args).call
    end

    def initialize(user_prompt:, style: nil, tags: [], user: nil, anonymous_identity: nil, source: "create", design: nil)
      @user_prompt = user_prompt
      @style = style
      @tags = tags
      @user = user
      @anonymous_identity = anonymous_identity
      @source = source
      @design = design
    end

    def call
      generation = ActiveRecord::Base.transaction do
        design = find_or_create_design
        create_prompt(design)
        gen = create_generation(design)
        create_variants(gen)
        gen
      end

      GenerationJob.perform_later(generation.id)
      generation
    end

    private

    def find_or_create_design
      return @design if @design

      Design.create!(
        user: @user,
        style: @style,
        base_prompt: @user_prompt,
        title: @user_prompt.truncate(100),
        source_design_id: nil
      )
    end

    def create_prompt(design)
      return if design.prompt

      design.create_prompt!(current_text: @user_prompt)
    end

    def create_generation(design)
      design.generations.create!(
        user: @user,
        anonymous_identity: @anonymous_identity,
        source: @source,
        status: "created",
        provider: provider_name,
        preset_snapshot: @style&.generation_preset || {},
        tags_snapshot: { tags: @tags.map(&:slug) }
      )
    end

    def create_variants(generation)
      # Main variant
      main_result = PromptComposer.call(
        user_prompt: @user_prompt,
        style: @style,
        tags: @tags
      )
      generation.generation_variants.create!(
        kind: "main",
        composed_prompt: main_result[:composed_prompt]
      )

      # Mutations
      mutations = TagMutationEngine.call(base_tags: @tags, style: @style)

      mutations.each_with_index do |mutation, idx|
        kind = idx == 0 ? "mutation_a" : "mutation_b"
        mutated_tags = (@tags - mutation[:tags_removed]) + mutation[:tags_added]

        result = PromptComposer.call(
          user_prompt: @user_prompt,
          style: @style,
          tags: mutated_tags
        )

        generation.generation_variants.create!(
          kind: kind,
          composed_prompt: result[:composed_prompt],
          mutation_summary: mutation[:summary],
          mutation_tags_added: mutation[:tags_added].map(&:slug),
          mutation_tags_removed: mutation[:tags_removed].map(&:slug)
        )
      end
    end

    def provider_name
      AppSetting["generation_provider"]&.fetch("value", "test") || "test"
    end
  end
end
