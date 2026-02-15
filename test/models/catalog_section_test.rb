require "test_helper"

class CatalogSectionTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:catalog_section).valid?
  end

  test "invalid without name" do
    assert_not build(:catalog_section, name: nil).valid?
  end

  test "invalid without slug" do
    assert_not build(:catalog_section, slug: nil).valid?
  end

  test "slug must be unique" do
    create(:catalog_section, slug: "editorial")
    assert_not build(:catalog_section, slug: "editorial").valid?
  end

  test "section_type enum uses string values" do
    section = create(:catalog_section, section_type: "popular")
    raw = CatalogSection.connection.select_value("SELECT section_type FROM catalog_sections WHERE id = #{section.id}")
    assert_equal "popular", raw
  end

  test "active scope" do
    active = create(:catalog_section, is_active: true)
    create(:catalog_section, is_active: false)
    assert_equal [ active ], CatalogSection.active.to_a
  end
end
