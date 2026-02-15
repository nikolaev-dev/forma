require "test_helper"

class PromptVersionTest < ActiveSupport::TestCase
  test "valid with required fields" do
    prompt = create(:prompt)
    assert PromptVersion.new(prompt: prompt, text: "some text").valid?
  end

  test "invalid without text" do
    prompt = create(:prompt)
    assert_not PromptVersion.new(prompt: prompt, text: nil).valid?
  end

  test "invalid without prompt" do
    assert_not PromptVersion.new(text: "some text").valid?
  end

  test "changed_by_user is optional" do
    prompt = create(:prompt)
    assert PromptVersion.new(prompt: prompt, text: "text", changed_by_user: nil).valid?
  end

  test "stores change_reason and diff_summary" do
    prompt = create(:prompt)
    version = prompt.prompt_versions.create!(
      text: "new text",
      change_reason: "style change",
      diff_summary: "added mood keywords"
    )
    assert_equal "style change", version.change_reason
    assert_equal "added mood keywords", version.diff_summary
  end
end
