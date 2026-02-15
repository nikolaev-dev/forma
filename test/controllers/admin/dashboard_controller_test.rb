require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
  end

  test "redirects non-admin to root" do
    user = create(:user)
    sign_in_as(user)
    get admin_root_path
    assert_redirected_to root_path
  end

  test "renders dashboard for admin" do
    sign_in_as(@admin)
    get admin_root_path
    assert_response :success
    assert_match "Дашборд", response.body
  end

  test "redirects unauthenticated user" do
    get admin_root_path
    assert_redirected_to root_path
  end
end
