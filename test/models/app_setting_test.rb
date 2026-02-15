require "test_helper"

class AppSettingTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:app_setting).valid?
  end

  test "invalid without key" do
    assert_not build(:app_setting, key: nil).valid?
  end

  test "key must be unique" do
    create(:app_setting, key: "test_key")
    assert_not build(:app_setting, key: "test_key").valid?
  end

  test "bracket method reads value" do
    create(:app_setting, key: "test_key", value: { "answer" => 42 })
    assert_equal({ "answer" => 42 }, AppSetting["test_key"])
  end

  test "bracket method returns nil for missing key" do
    assert_nil AppSetting["nonexistent"]
  end

  test "set creates new setting" do
    user = create(:user, :admin)
    AppSetting.set("new_key", { "val" => 1 }, user: user)

    setting = AppSetting.find_by(key: "new_key")
    assert_not_nil setting
    assert_equal({ "val" => 1 }, setting.value)
    assert_equal user, setting.updated_by_user
  end

  test "set updates existing setting" do
    create(:app_setting, key: "update_me", value: { "old" => true })
    AppSetting.set("update_me", { "new" => true })

    assert_equal({ "new" => true }, AppSetting["update_me"])
  end
end
