require "test_helper"

class Api::CatalogControllerTest < ActionDispatch::IntegrationTest
  test "styles returns published styles as JSON" do
    style = create(:style, :published, name: "Тестовый стиль", slug: "test-api-style")
    tag = create(:tag)
    create(:style_tag, style: style, tag: tag)

    get api_catalog_styles_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    slugs = json.map { |s| s["slug"] }
    assert_includes slugs, "test-api-style"

    found = json.find { |s| s["slug"] == "test-api-style" }
    assert_equal "Тестовый стиль", found["name"]
    assert found["tags"].any?
  end

  test "styles does not include draft styles" do
    create(:style, status: "draft", slug: "draft-style")
    get api_catalog_styles_path
    json = JSON.parse(response.body)
    slugs = json.map { |s| s["slug"] }
    assert_not_includes slugs, "draft-style"
  end

  test "sections returns catalog sections with items" do
    section = create(:catalog_section, name: "Тест секция", slug: "test-section")
    style = create(:style, :published)
    create(:catalog_item, catalog_section: section, item: style)

    get api_catalog_sections_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    found = json.find { |s| s["slug"] == "test-section" }
    assert found.present?
    assert_equal "Тест секция", found["name"]
    assert found["items"].any?
  end
end
