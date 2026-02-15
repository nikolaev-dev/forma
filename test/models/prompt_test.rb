require "test_helper"

class PromptTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:prompt).valid?
  end

  test "invalid without current_text" do
    assert_not build(:prompt, current_text: nil).valid?
  end

  test "belongs to design" do
    prompt = create(:prompt)
    assert_instance_of Design, prompt.design
  end

  test "has many prompt_versions" do
    prompt = create(:prompt)
    prompt.prompt_versions.create!(text: "v1")
    prompt.prompt_versions.create!(text: "v2")
    assert_equal 2, prompt.prompt_versions.count
  end

  test "destroying prompt destroys versions" do
    prompt = create(:prompt)
    prompt.prompt_versions.create!(text: "v1")
    assert_difference "PromptVersion.count", -1 do
      prompt.destroy!
    end
  end

  test "update_text! creates version and updates current_text" do
    prompt = create(:prompt, current_text: "original")
    prompt.update_text!("updated", reason: "improve")
    assert_equal "updated", prompt.reload.current_text
    assert_equal 1, prompt.prompt_versions.count
    version = prompt.prompt_versions.last
    assert_equal "updated", version.text
    assert_equal "improve", version.change_reason
  end

  test "update_text! with user tracks who changed" do
    user = create(:user)
    prompt = create(:prompt, current_text: "original")
    prompt.update_text!("new text", user: user)
    assert_equal user, prompt.prompt_versions.last.changed_by_user
  end
end
