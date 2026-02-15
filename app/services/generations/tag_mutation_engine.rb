module Generations
  class TagMutationEngine
    # Generates tag mutations for variant A and B.
    #
    # @param base_tags [Array<Tag>] original tags from user
    # @param style [Style, nil] selected style
    # @return [Array<Hash>] two mutation configs, each: { tags_added:, tags_removed:, summary: }
    def self.call(base_tags:, style: nil)
      new(base_tags:, style:).call
    end

    def initialize(base_tags:, style: nil)
      @base_tags = base_tags
      @style = style
      @base_tag_ids = base_tags.map(&:id).to_set
    end

    def call
      candidates = find_candidates
      [
        build_mutation(candidates, :mutation_a),
        build_mutation(candidates, :mutation_b)
      ]
    end

    private

    def find_candidates
      # Get related tags from tag_relations
      related_ids = TagRelation.where(from_tag_id: @base_tag_ids, relation_type: "related")
                               .pluck(:to_tag_id)

      # Get tags from same categories
      category_ids = @base_tags.map(&:tag_category_id).uniq
      category_peers = Tag.where(tag_category_id: category_ids)
                          .where.not(id: @base_tag_ids.to_a)
                          .available
                          .pluck(:id)

      # Merge and exclude conflicts
      conflicting_ids = TagRelation.where(
        from_tag_id: @base_tag_ids,
        relation_type: %w[conflicts_with discouraged_with]
      ).pluck(:to_tag_id).to_set

      all_candidate_ids = (related_ids + category_peers).uniq - @base_tag_ids.to_a - conflicting_ids.to_a
      Tag.where(id: all_candidate_ids).available.to_a
    end

    def build_mutation(candidates, kind)
      return empty_mutation if candidates.empty?

      # Pick 1-2 random tags to add
      tags_to_add = candidates.sample(rand(1..2))

      # Optionally replace one base tag
      tags_to_remove = []
      if @base_tags.size > 1 && rand < 0.4
        replaceable = @base_tags.select { |t| !primary_tag?(t) }
        tags_to_remove = replaceable.sample(1)
      end

      summary = build_summary(tags_to_add, tags_to_remove)

      {
        tags_added: tags_to_add,
        tags_removed: tags_to_remove,
        summary: summary
      }
    end

    def primary_tag?(tag)
      return false unless @style
      StyleTag.exists?(style: @style, tag: tag, is_primary: true)
    end

    def build_summary(added, removed)
      parts = []
      parts << "Добавили: #{added.map(&:name).join(', ')}" if added.any?
      parts << "Убрали: #{removed.map(&:name).join(', ')}" if removed.any?
      parts.join(". ")
    end

    def empty_mutation
      { tags_added: [], tags_removed: [], summary: "" }
    end
  end
end
