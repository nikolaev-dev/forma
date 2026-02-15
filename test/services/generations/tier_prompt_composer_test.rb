require "test_helper"

class Generations::TierPromptComposerTest < ActiveSupport::TestCase
  setup do
    @core = create(:tier_modifier, :core,
      negative_prompt: "cartoon, illustration, low resolution",
      settings: { "aspect_ratio" => "2:3", "lens" => "50mm" })
    @signature = create(:tier_modifier, :signature,
      negative_prompt: "cartoon, illustration, low resolution",
      settings: { "aspect_ratio" => "2:3", "lens" => "50mm" })
    @lux = create(:tier_modifier, :lux,
      negative_prompt: "cartoon, illustration, low resolution",
      settings: { "aspect_ratio" => "2:3", "lens" => "50mm", "style_notes" => "leather grain" })
  end

  test "composes prompt with scene setup" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "Japanese zen garden",
      tier: "core"
    )

    assert result[:composed_prompt].start_with?(Generations::TierPromptComposer::SCENE_SETUP)
  end

  test "includes curated prompt" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "Japanese zen garden",
      tier: "core"
    )

    assert_includes result[:composed_prompt], "Japanese zen garden"
  end

  test "includes tier modifier prompt" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "Japanese zen garden",
      tier: "core"
    )

    assert_includes result[:composed_prompt], @core.prompt_modifier
  end

  test "includes identity elements" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "Japanese zen garden",
      tier: "core"
    )

    assert_includes result[:composed_prompt], @core.identity_elements
  end

  test "includes policy suffix" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "Japanese zen garden",
      tier: "core"
    )

    assert result[:composed_prompt].end_with?(Generations::TierPromptComposer::POLICY_SUFFIX)
  end

  test "returns negative prompt from tier modifier" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "Japanese zen garden",
      tier: "core"
    )

    assert_equal @core.negative_prompt, result[:negative_prompt]
  end

  test "returns tier" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "test",
      tier: "signature"
    )

    assert_equal "signature", result[:tier]
  end

  test "returns settings from tier modifier" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "test",
      tier: "lux"
    )

    assert_equal @lux.settings, result[:settings]
  end

  test "handles blank curated prompt" do
    result = Generations::TierPromptComposer.call(
      curated_prompt: "",
      tier: "core"
    )

    assert result[:composed_prompt].present?
    assert_not_includes result[:composed_prompt], ", , "
  end

  test "raises when tier modifier not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Generations::TierPromptComposer.call(
        curated_prompt: "test",
        tier: "nonexistent"
      )
    end
  end

  test "different tiers produce different prompts" do
    core_result = Generations::TierPromptComposer.call(curated_prompt: "garden", tier: "core")
    lux_result = Generations::TierPromptComposer.call(curated_prompt: "garden", tier: "lux")

    assert_not_equal core_result[:composed_prompt], lux_result[:composed_prompt]
  end
end
