require "test_helper"

class GenerationVariantTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:generation_variant).valid?
  end

  test "invalid without composed_prompt" do
    assert_not build(:generation_variant, composed_prompt: nil).valid?
  end

  test "kind must be unique per generation" do
    gen = create(:generation)
    create(:generation_variant, :main, generation: gen)
    assert_not build(:generation_variant, :main, generation: gen).valid?
  end

  test "kind enum uses string values" do
    variant = create(:generation_variant, kind: "mutation_a")
    raw = GenerationVariant.connection.select_value("SELECT kind FROM generation_variants WHERE id = #{variant.id}")
    assert_equal "mutation_a", raw
  end

  test "status enum uses string values" do
    variant = create(:generation_variant, status: "succeeded")
    raw = GenerationVariant.connection.select_value("SELECT status FROM generation_variants WHERE id = #{variant.id}")
    assert_equal "succeeded", raw
  end

  test "succeed! transitions status" do
    variant = create(:generation_variant, status: "running")
    variant.succeed!({ test: true })
    assert_equal "succeeded", variant.status
    assert_equal({ "test" => true }, variant.provider_metadata)
  end

  test "fail! transitions status with error details" do
    variant = create(:generation_variant, status: "running")
    variant.fail!(code: "timeout", message: "Provider timeout")
    assert_equal "failed", variant.status
    assert_equal "timeout", variant.error_code
    assert_equal "Provider timeout", variant.error_message
  end
end
