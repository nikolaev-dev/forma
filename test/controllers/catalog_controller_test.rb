require "test_helper"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get root_path
    assert_response :success
  end

  test "index renders FORMA header" do
    get root_path
    assert_select "h1", "FORMA"
  end

  test "index shows editorial styles" do
    editorial = create(:style, name: "Минимализм", popularity_score: 5.0)
    regular = create(:style, name: "Обычный", popularity_score: 2.0)

    get root_path
    assert_response :success
    assert_match "Минимализм", response.body
  end

  test "index shows popular styles" do
    popular = create(:style, name: "Популярный", popularity_score: 3.0)

    get root_path
    assert_response :success
    assert_match "Популярный", response.body
  end

  test "index shows active catalog sections" do
    section = create(:catalog_section, name: "Новинки", is_active: true, section_type: "new")
    style = create(:style, name: "В секции")
    create(:catalog_item, catalog_section: section, item: style)

    get root_path
    assert_response :success
    assert_match "Новинки", response.body
  end

  test "index does not show inactive catalog sections" do
    section = create(:catalog_section, name: "Скрытая", is_active: false)

    get root_path
    assert_response :success
    assert_no_match "Скрытая", response.body
  end

  test "index does not show draft styles" do
    create(:style, :draft, name: "Черновик")

    get root_path
    assert_response :success
    assert_no_match "Черновик", response.body
  end

  test "catalog path also works" do
    get catalog_path
    assert_response :success
  end
end
