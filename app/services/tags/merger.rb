module Tags
  class Merger
    def self.call(source:, target:)
      new(source, target).call
    end

    def initialize(source, target)
      @source = source
      @target = target
    end

    def call
      ActiveRecord::Base.transaction do
        move_style_tags
        move_design_tags
        move_synonyms
        move_relations
        @source.destroy!
      end
    end

    private

    def move_style_tags
      StyleTag.where(tag_id: @source.id).find_each do |st|
        if StyleTag.exists?(style_id: st.style_id, tag_id: @target.id)
          st.destroy!
        else
          st.update!(tag_id: @target.id)
        end
      end
    end

    def move_design_tags
      DesignTag.where(tag_id: @source.id).find_each do |dt|
        if DesignTag.exists?(design_id: dt.design_id, tag_id: @target.id)
          dt.destroy!
        else
          dt.update!(tag_id: @target.id)
        end
      end
    end

    def move_synonyms
      @source.tag_synonyms.find_each do |syn|
        existing = TagSynonym.find_by(normalized: syn.normalized)
        if existing && existing.tag_id != @source.id
          syn.destroy!
        else
          syn.update!(tag_id: @target.id)
        end
      end
    end

    def move_relations
      TagRelation.where(from_tag_id: @source.id).find_each do |rel|
        if TagRelation.exists?(from_tag_id: @target.id, to_tag_id: rel.to_tag_id, relation_type: rel.relation_type)
          rel.destroy!
        else
          rel.update!(from_tag_id: @target.id)
        end
      end

      TagRelation.where(to_tag_id: @source.id).find_each do |rel|
        if TagRelation.exists?(from_tag_id: rel.from_tag_id, to_tag_id: @target.id, relation_type: rel.relation_type)
          rel.destroy!
        else
          rel.update!(to_tag_id: @target.id)
        end
      end
    end
  end
end
