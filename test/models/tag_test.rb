require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:tag).valid?
  end

  test "invalid without name" do
    assert_not build(:tag, name: nil).valid?
  end

  test "invalid without slug" do
    assert_not build(:tag, slug: nil).valid?
  end

  test "slug must be unique" do
    create(:tag, slug: "japan")
    assert_not build(:tag, slug: "japan").valid?
  end

  test "visibility enum uses string values" do
    tag = create(:tag, visibility: "hidden")
    raw = Tag.connection.select_value("SELECT visibility FROM tags WHERE id = #{tag.id}")
    assert_equal "hidden", raw
  end

  test "kind enum uses string values" do
    tag = create(:tag, kind: "brand_mood")
    raw = Tag.connection.select_value("SELECT kind FROM tags WHERE id = #{tag.id}")
    assert_equal "brand_mood", raw
  end

  test "weight must be non-negative" do
    assert_not build(:tag, weight: -1).valid?
  end

  test "available scope excludes banned and hidden" do
    available = create(:tag, visibility: "public", is_banned: false)
    create(:tag, :hidden)
    create(:tag, :banned)
    assert_equal [ available ], Tag.available.to_a
  end

  test "trigram search finds by partial name" do
    create(:tag, name: "Марокко", slug: "morocco")
    create(:tag, name: "Мрамор", slug: "marble")
    results = Tag.search_by_name("Мар")
    assert_includes results.map(&:name), "Марокко"
  end

  test "belongs to tag_category" do
    tag = create(:tag)
    assert tag.tag_category.present?
  end

  test "has many tag_synonyms" do
    tag = create(:tag)
    create(:tag_synonym, tag: tag, phrase: "синоним")
    assert_equal 1, tag.tag_synonyms.count
  end
end
