require "test_helper"

class Generations::TrainingPipelineTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @core = create(:tier_modifier, :core,
      negative_prompt: "cartoon, illustration",
      settings: { "aspect_ratio" => "2:3" })
    @signature = create(:tier_modifier, :signature,
      negative_prompt: "cartoon, illustration",
      settings: { "aspect_ratio" => "2:3" })
    @lux = create(:tier_modifier, :lux,
      negative_prompt: "cartoon, illustration",
      settings: { "aspect_ratio" => "2:3" })

    @user = create(:user, role: "admin")
    @collection = create(:collection)
    @ref = create(:reference_image, :curated, collection: @collection)
  end

  test "creates Design from curated reference image" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    design = generation.design
    assert design.persisted?
    assert_equal @ref.curated_prompt, design.base_prompt
    assert_equal @collection, design.collection
    assert_equal @user, design.user
    assert_equal "private", design.visibility
  end

  test "creates Generation with training_pipeline source" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    assert generation.persisted?
    assert_equal "training_pipeline", generation.source
    assert_equal "created", generation.status
    assert_equal "test", generation.provider
  end

  test "creates 3 tier variants (core, signature, lux)" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    variants = generation.generation_variants.order(:tier)
    assert_equal 3, variants.count

    tiers = variants.map(&:tier).sort
    assert_equal %w[core lux signature], tiers

    variants.each do |v|
      assert_equal "main", v.kind
      assert_equal "created", v.status
      assert v.composed_prompt.present?
    end
  end

  test "tier variants have different composed prompts" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    prompts = generation.generation_variants.map(&:composed_prompt)
    assert_equal prompts.uniq.size, prompts.size, "Each tier should have a unique prompt"
  end

  test "composed prompts include curated prompt" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    generation.generation_variants.each do |v|
      assert_includes v.composed_prompt, @ref.curated_prompt
    end
  end

  test "marks reference image as generated with design" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    @ref.reload
    assert_equal "generated", @ref.status
    assert_equal generation.design, @ref.design
  end

  test "enqueues GenerationJob" do
    assert_enqueued_jobs 1, only: GenerationJob do
      Generations::TrainingPipeline.call(
        reference_image: @ref,
        user: @user
      )
    end
  end

  test "raises when reference image is not curated" do
    ref = create(:reference_image, status: "uploaded")

    assert_raises(RuntimeError, "ReferenceImage must be curated") do
      Generations::TrainingPipeline.call(reference_image: ref, user: @user)
    end
  end

  test "raises when curated_prompt is blank" do
    @ref.update_column(:curated_prompt, nil)
    @ref.reload

    assert_raises(RuntimeError) do
      Generations::TrainingPipeline.call(reference_image: @ref, user: @user)
    end
  end

  test "accepts custom provider" do
    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user,
      provider: "stable_diffusion"
    )

    assert_equal "stable_diffusion", generation.provider
  end

  test "design title is truncated from curated_prompt" do
    long_prompt = "A" * 200
    @ref.update_column(:curated_prompt, long_prompt)
    @ref.reload

    generation = Generations::TrainingPipeline.call(
      reference_image: @ref,
      user: @user
    )

    assert generation.design.title.length <= 100
  end
end
