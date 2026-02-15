require "test_helper"

class TagCategoryTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:tag_category).valid?
  end

  test "invalid without name" do
    assert_not build(:tag_category, name: nil).valid?
  end

  test "invalid without slug" do
    assert_not build(:tag_category, slug: nil).valid?
  end

  test "slug must be unique" do
    create(:tag_category, slug: "moods")
    assert_not build(:tag_category, slug: "moods").valid?
  end

  test "has many tags" do
    category = create(:tag_category)
    create_list(:tag, 3, tag_category: category)
    assert_equal 3, category.tags.count
  end

  test "active scope" do
    active = create(:tag_category, is_active: true)
    create(:tag_category, is_active: false)
    assert_includes TagCategory.active, active
    assert_equal 1, TagCategory.active.count
  end

  test "ordered scope" do
    c3 = create(:tag_category, position: 3)
    c1 = create(:tag_category, position: 1)
    c2 = create(:tag_category, position: 2)
    assert_equal [ c1, c2, c3 ], TagCategory.ordered.to_a
  end
end
