require "test_helper"

class DesignTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:design).valid?
  end

  test "visibility enum uses string values" do
    design = create(:design, visibility: "public")
    raw = Design.connection.select_value("SELECT visibility FROM designs WHERE id = #{design.id}")
    assert_equal "public", raw
  end

  test "moderation_status enum uses string values" do
    design = create(:design, moderation_status: "requires_review")
    raw = Design.connection.select_value("SELECT moderation_status FROM designs WHERE id = #{design.id}")
    assert_equal "requires_review", raw
  end

  test "generates hashid" do
    design = create(:design)
    assert design.hashid.present?
    assert design.hashid.length >= 6
  end

  test "full-text search by title" do
    create(:design, title: "Японский минимализм в дизайне")
    results = Design.search("японский")
    assert_equal 1, results.count
  end

  test "full-text search by base_prompt" do
    create(:design, base_prompt: "создай обложку в стиле ренессанс")
    results = Design.search("ренессанс")
    assert_equal 1, results.count
  end

  test "published scope" do
    create(:design, visibility: "public")
    create(:design, visibility: "private")
    assert_equal 1, Design.published.count
  end

  test "has many tags through design_tags" do
    design = create(:design)
    tag = create(:tag)
    create(:design_tag, design: design, tag: tag)
    assert_includes design.tags, tag
  end

  test "remix association" do
    original = create(:design)
    remix = create(:design, source_design_id: original.id)
    assert_equal original, remix.source_design
    assert_includes original.remixes, remix
  end
end
