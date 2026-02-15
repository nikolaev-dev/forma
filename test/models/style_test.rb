require "test_helper"

class StyleTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:style).valid?
  end

  test "invalid without name" do
    assert_not build(:style, name: nil).valid?
  end

  test "invalid without slug" do
    assert_not build(:style, slug: nil).valid?
  end

  test "slug must be unique" do
    create(:style, slug: "japanese")
    assert_not build(:style, slug: "japanese").valid?
  end

  test "status enum uses string values" do
    style = create(:style, status: "draft")
    raw = Style.connection.select_value("SELECT status FROM styles WHERE id = #{style.id}")
    assert_equal "draft", raw
  end

  test "published scope" do
    published = create(:style, status: "published")
    create(:style, :draft)
    assert_equal [ published ], Style.published.to_a
  end

  test "editorial scope returns high-rated published styles" do
    editorial = create(:style, status: "published", popularity_score: 4.5)
    create(:style, status: "published", popularity_score: 2.0)
    assert_includes Style.editorial, editorial
  end

  test "has many tags through style_tags" do
    style = create(:style)
    tag = create(:tag)
    create(:style_tag, style: style, tag: tag)
    assert_includes style.tags, tag
  end

  test "generates hashid" do
    style = create(:style)
    assert style.hashid.present?
    assert style.hashid.length >= 6
  end
end
