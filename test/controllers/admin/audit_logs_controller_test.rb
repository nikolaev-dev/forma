require "test_helper"

class Admin::AuditLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in_as(@admin)
  end

  test "index renders audit log page" do
    AuditLog.log!(actor: @admin, action: "test.action")

    get admin_audit_logs_path
    assert_response :success
    assert_match "test.action", response.body
  end

  test "index filters by action" do
    AuditLog.log!(actor: @admin, action: "tag.create")
    AuditLog.log!(actor: @admin, action: "style.create")

    get admin_audit_logs_path(action_filter: "tag.create")
    assert_response :success
    assert_match "tag.create", response.body
  end
end
