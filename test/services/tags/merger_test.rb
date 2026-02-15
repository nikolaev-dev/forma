require "test_helper"

class Tags::MergerTest < ActiveSupport::TestCase
  setup do
    @source = create(:tag, name: "Дубль", slug: "duplicate")
    @target = create(:tag, name: "Оригинал", slug: "original")
  end

  test "destroys source tag" do
    Tags::Merger.call(source: @source, target: @target)
    assert_not Tag.exists?(@source.id)
  end

  test "moves style_tags to target" do
    style = create(:style, slug: "test-style")
    StyleTag.create!(style: style, tag: @source)

    Tags::Merger.call(source: @source, target: @target)

    assert StyleTag.exists?(style_id: style.id, tag_id: @target.id)
    assert_not StyleTag.exists?(tag_id: @source.id)
  end

  test "does not duplicate style_tags" do
    style = create(:style, slug: "test-style2")
    StyleTag.create!(style: style, tag: @source)
    StyleTag.create!(style: style, tag: @target)

    Tags::Merger.call(source: @source, target: @target)

    assert_equal 1, StyleTag.where(style_id: style.id, tag_id: @target.id).count
  end

  test "moves design_tags to target" do
    design = create(:design)
    DesignTag.create!(design: design, tag: @source)

    Tags::Merger.call(source: @source, target: @target)

    assert DesignTag.exists?(design_id: design.id, tag_id: @target.id)
  end

  test "moves synonyms to target" do
    @source.tag_synonyms.create!(phrase: "dup phrase")

    Tags::Merger.call(source: @source, target: @target)

    assert TagSynonym.exists?(tag_id: @target.id, phrase: "dup phrase")
  end

  test "moves tag_relations to target" do
    other = create(:tag, slug: "other")
    TagRelation.create!(from_tag: @source, to_tag: other, relation_type: "related")

    Tags::Merger.call(source: @source, target: @target)

    assert TagRelation.exists?(from_tag_id: @target.id, to_tag_id: other.id)
  end
end
