require "test_helper"

class TierModifierTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:tier_modifier).valid?
  end

  test "invalid without tier" do
    assert_not build(:tier_modifier, tier: nil).valid?
  end

  test "invalid without prompt_modifier" do
    assert_not build(:tier_modifier, prompt_modifier: nil).valid?
  end

  test "tier must be unique" do
    create(:tier_modifier, tier: "core")
    assert_not build(:tier_modifier, tier: "core").valid?
  end

  test "tier enum uses string values" do
    modifier = create(:tier_modifier, tier: "signature")
    raw = TierModifier.connection.select_value("SELECT tier FROM tier_modifiers WHERE id = #{modifier.id}")
    assert_equal "signature", raw
  end

  test "only allows valid tiers" do
    assert_raises(ArgumentError) { build(:tier_modifier, tier: "premium") }
  end

  test ".for finds by tier" do
    modifier = create(:tier_modifier, :core)
    assert_equal modifier, TierModifier.for("core")
  end

  test ".for raises when not found" do
    assert_raises(ActiveRecord::RecordNotFound) { TierModifier.for("core") }
  end

  test ".ordered returns core, signature, lux" do
    lux = create(:tier_modifier, :lux)
    core = create(:tier_modifier, :core)
    sig = create(:tier_modifier, :signature)
    assert_equal [core, sig, lux], TierModifier.ordered.to_a
  end

  test "settings is jsonb" do
    modifier = create(:tier_modifier, settings: { aspect_ratio: "2:3", lens: "50mm" })
    modifier.reload
    assert_equal "2:3", modifier.settings["aspect_ratio"]
    assert_equal "50mm", modifier.settings["lens"]
  end

  test "TIERS constant lists all valid tiers" do
    assert_equal %w[core signature lux], TierModifier::TIERS
  end
end
