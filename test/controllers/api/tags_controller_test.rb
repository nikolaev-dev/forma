require "test_helper"

class Api::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = create(:tag_category, name: "Тема", slug: "theme", is_active: true)
  end

  test "search returns matching tags as json" do
    create(:tag, name: "Минимализм", slug: "minimalism", tag_category: @category)
    create(:tag, name: "Минотавр", slug: "minotaur", tag_category: @category)

    get api_tags_search_path, params: { q: "мини" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json["tags"].is_a?(Array)
    assert json["tags"].length >= 1
  end

  test "search returns empty array for no match" do
    get api_tags_search_path, params: { q: "xyznonexistent" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal [], json["tags"]
  end

  test "search excludes banned tags" do
    create(:tag, :banned, name: "Banned", slug: "banned-tag", tag_category: @category)

    get api_tags_search_path, params: { q: "banned" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal [], json["tags"]
  end

  test "search limits results to 10" do
    15.times do |i|
      create(:tag, name: "Тег#{i}", slug: "search-tag-#{i}", tag_category: @category)
    end

    get api_tags_search_path, params: { q: "тег" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json["tags"].length <= 10
  end

  test "search returns 400 without query" do
    get api_tags_search_path
    assert_response :bad_request
  end
end
