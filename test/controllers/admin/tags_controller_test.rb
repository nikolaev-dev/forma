require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in_as(@admin)
    @category = create(:tag_category, name: "Тест", slug: "test-cat")
    @tag = create(:tag, name: "Огонь", slug: "fire", tag_category: @category)
  end

  test "index lists tags" do
    get admin_tags_path
    assert_response :success
    assert_match "Огонь", response.body
  end

  test "index filters by category" do
    other_cat = create(:tag_category, name: "Другая", slug: "other")
    create(:tag, name: "Вода", slug: "water", tag_category: other_cat)

    get admin_tags_path(category_id: @category.id)
    assert_response :success
    assert_match "Огонь", response.body
  end

  test "index filters by search query" do
    get admin_tags_path(q: "Огонь")
    assert_response :success
    assert_match "Огонь", response.body
  end

  test "new renders form" do
    get new_admin_tag_path
    assert_response :success
  end

  test "create creates tag with audit log" do
    assert_difference [ "Tag.count", "AuditLog.count" ], 1 do
      post admin_tags_path, params: {
        tag: { name: "Лёд", slug: "ice", tag_category_id: @category.id, visibility: "public", kind: "generic", weight: 1.0 }
      }
    end
    assert_redirected_to admin_tags_path
    assert_equal "tag.create", AuditLog.last.action
  end

  test "edit renders form" do
    get edit_admin_tag_path(@tag)
    assert_response :success
    assert_match "Огонь", response.body
  end

  test "update updates tag with audit log" do
    patch admin_tag_path(@tag), params: { tag: { name: "Огонь обновлённый" } }
    assert_redirected_to admin_tags_path
    assert_equal "Огонь обновлённый", @tag.reload.name
    assert_equal "tag.update", AuditLog.last.action
  end

  test "destroy deletes tag with audit log" do
    assert_difference "Tag.count", -1 do
      delete admin_tag_path(@tag)
    end
    assert_redirected_to admin_tags_path
    assert_equal "tag.delete", AuditLog.last.action
  end

  test "merge merges source into target" do
    target = create(:tag, name: "Пламя", slug: "flame", tag_category: @category)
    style = create(:style, slug: "test-merge")
    StyleTag.create!(style: style, tag: @tag)

    post merge_admin_tag_path(@tag), params: { target_tag_id: target.id }

    assert_redirected_to admin_tags_path
    assert_not Tag.exists?(@tag.id)
    assert StyleTag.exists?(style_id: style.id, tag_id: target.id)
  end
end
