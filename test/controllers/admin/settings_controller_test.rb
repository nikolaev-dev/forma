require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in_as(@admin)
    @setting = AppSetting.find_or_create_by!(key: "test_setting") do |s|
      s.value = { "value" => 42 }
      s.updated_by_user = @admin
    end
  end

  test "index lists settings" do
    get admin_settings_path
    assert_response :success
    assert_match "test_setting", response.body
  end

  test "update changes setting value with audit log" do
    patch admin_setting_path(key: "test_setting"), params: {
      setting: { value: '{"value": 100}' }
    }
    assert_redirected_to admin_settings_path
    assert_equal({ "value" => 100 }, @setting.reload.value)
    assert_equal "settings.update", AuditLog.last.action
  end
end
