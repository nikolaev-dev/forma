require "test_helper"

class StyleTagTest < ActiveSupport::TestCase
  test "valid with style and tag" do
    st = build(:style_tag)
    assert st.valid?
  end

  test "requires style" do
    st = StyleTag.new(tag: create(:tag))
    assert_not st.valid?
  end

  test "requires tag" do
    st = StyleTag.new(style: create(:style))
    assert_not st.valid?
  end

  test "unique tag per style" do
    st = create(:style_tag)
    duplicate = build(:style_tag, style: st.style, tag: st.tag)
    assert_not duplicate.valid?
  end

  test "same tag can belong to different styles" do
    tag = create(:tag)
    style1 = create(:style)
    style2 = create(:style)
    create(:style_tag, style: style1, tag: tag)
    st = build(:style_tag, style: style2, tag: tag)
    assert st.valid?
  end
end
