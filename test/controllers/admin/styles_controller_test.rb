require "test_helper"

class Admin::StylesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in_as(@admin)
    @style = create(:style, name: "Тестовый", slug: "test-admin-style", status: "draft")
  end

  test "index lists styles" do
    get admin_styles_path
    assert_response :success
    assert_match "Тестовый", response.body
  end

  test "index filters by status" do
    get admin_styles_path(status: "draft")
    assert_response :success
    assert_match "Тестовый", response.body
  end

  test "new renders form" do
    get new_admin_style_path
    assert_response :success
  end

  test "create creates style with audit log" do
    assert_difference [ "Style.count", "AuditLog.count" ], 1 do
      post admin_styles_path, params: {
        style: { name: "Новый стиль", slug: "new-admin-style", status: "draft" }
      }
    end
    assert_redirected_to admin_styles_path
  end

  test "edit renders form" do
    get edit_admin_style_path(@style)
    assert_response :success
  end

  test "update updates style" do
    patch admin_style_path(@style), params: { style: { name: "Обновлённый" } }
    assert_redirected_to admin_styles_path
    assert_equal "Обновлённый", @style.reload.name
  end

  test "publish changes status to published" do
    patch publish_admin_style_path(@style)
    assert_redirected_to admin_styles_path
    assert_equal "published", @style.reload.status
    assert_equal "style.publish", AuditLog.last.action
  end

  test "hide changes status to hidden" do
    @style.update!(status: "published")
    patch hide_admin_style_path(@style)
    assert_redirected_to admin_styles_path
    assert_equal "hidden", @style.reload.status
    assert_equal "style.hide", AuditLog.last.action
  end

  test "destroy deletes draft style" do
    assert_difference "Style.count", -1 do
      delete admin_style_path(@style)
    end
    assert_redirected_to admin_styles_path
  end

  test "create with tags syncs style_tags" do
    tag1 = create(:tag)
    tag2 = create(:tag)

    post admin_styles_path, params: {
      style: { name: "С тегами", slug: "with-tags", status: "draft" },
      tag_ids: [ tag1.id, tag2.id ]
    }

    style = Style.find_by(slug: "with-tags")
    assert_equal 2, style.style_tags.count
  end
end
