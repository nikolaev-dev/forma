require "test_helper"

class CatalogItemTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert create(:catalog_item).persisted?
  end

  test "invalid without item" do
    assert_not CatalogItem.new(catalog_section: create(:catalog_section)).valid?
  end

  test "belongs to catalog_section" do
    item = create(:catalog_item)
    assert_instance_of CatalogSection, item.catalog_section
  end

  test "polymorphic association with style" do
    style = create(:style)
    item = create(:catalog_item, item: style)
    assert_equal style, item.item
  end

  test "ordered scope sorts by position" do
    section = create(:catalog_section)
    second = create(:catalog_item, catalog_section: section, position: 2)
    first = create(:catalog_item, catalog_section: section, position: 1)
    assert_equal [first, second], CatalogItem.ordered.where(catalog_section: section).to_a
  end

  test "pinned scope" do
    pinned = create(:catalog_item, pinned: true)
    create(:catalog_item, pinned: false)
    assert_equal [pinned], CatalogItem.pinned.to_a
  end
end
