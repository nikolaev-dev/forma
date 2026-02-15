require "test_helper"

class TrainingPipelineFlowTest < ActiveSupport::TestCase
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

    @admin = create(:user, role: "admin")
    @collection = create(:collection, name: "Японские мотивы", slug: "japanese-motifs")
  end

  test "full training pipeline: batch → upload → analysis → curation → generation → publication" do
    # Step 1: Create batch and upload reference images
    batch = TrainingBatch.create!(
      name: "Партия 2026-02: японские мотивы",
      created_by_user: @admin
    )

    ref1 = batch.reference_images.create!(status: "uploaded")
    ref1.original_image.attach(
      io: StringIO.new("fake image data 1"),
      filename: "garden.jpg",
      content_type: "image/jpeg"
    )

    ref2 = batch.reference_images.create!(status: "uploaded")
    ref2.original_image.attach(
      io: StringIO.new("fake image data 2"),
      filename: "temple.jpg",
      content_type: "image/jpeg"
    )

    assert_equal "uploaded", batch.status
    assert_equal 2, batch.reload.images_count

    # Step 2: Start batch analysis
    batch.start_processing!
    assert_equal "processing", batch.status

    # Step 3: AI analysis (simulate results)
    ref1.start_analysis!
    assert_equal "analyzing", ref1.status

    claude_result = {
      "description" => "Японский сад с кленами",
      "base_prompt" => "Japanese zen garden with red maple trees",
      "suggested_tags" => %w[japan autumn garden],
      "mood" => "serene",
      "dominant_colors" => ["#8B0000", "#FFD700"],
      "visual_style" => "watercolor",
      "complexity" => "high"
    }

    openai_result = {
      "description" => "Тихий японский сад",
      "base_prompt" => "Tranquil Japanese garden with autumn foliage",
      "suggested_tags" => %w[japan garden nature],
      "mood" => "peaceful",
      "dominant_colors" => ["#8B0000", "#2F4F4F"],
      "visual_style" => "illustration",
      "complexity" => "medium"
    }

    ref1.update!(ai_analysis_claude: claude_result, ai_analysis_openai: openai_result)
    ref1.complete_analysis!
    assert_equal "analyzed", ref1.status

    # Step 4: Curation — curator selects Claude prompt and edits it
    ref1.curate!(
      prompt: "Japanese zen garden in autumn, red maple trees reflecting in koi pond, stone lantern, misty atmosphere",
      provider: "claude",
      collection: @collection,
      notes: "Claude prompt was better, added details about koi pond"
    )
    assert_equal "curated", ref1.status
    assert_equal "claude", ref1.selected_provider
    assert_equal @collection, ref1.collection

    # Step 5: 3-tier generation
    generation = perform_enqueued_jobs do
      Generations::TrainingPipeline.call(
        reference_image: ref1,
        user: @admin
      )
    end

    ref1.reload
    assert_equal "generated", ref1.status
    assert_not_nil ref1.design

    design = ref1.design
    assert_equal @collection, design.collection
    assert_equal "private", design.visibility

    generation.reload
    assert_equal "training_pipeline", generation.source
    assert_equal "succeeded", generation.status

    # All 3 tier variants should be succeeded
    variants = generation.generation_variants.order(:tier)
    assert_equal 3, variants.count
    variants.each do |v|
      assert_equal "main", v.kind
      assert_equal "succeeded", v.status
      assert v.preview_image.attached?
      assert_includes v.composed_prompt, ref1.curated_prompt
    end

    # Step 6: Publication
    ref1.publish!
    assert_equal "published", ref1.status

    design.update!(visibility: "public")
    assert_equal "public", design.visibility

    # Verify the design is in the collection
    assert_includes @collection.designs, design
  end

  test "rejection flow: batch → analysis → reject" do
    batch = create(:training_batch, created_by_user: @admin)
    ref = create(:reference_image, :analyzed, training_batch: batch)

    ref.reject!(notes: "Low quality image, not suitable for collection")
    assert_equal "rejected", ref.status
    assert_equal "Low quality image, not suitable for collection", ref.curator_notes
  end

  test "best_ai_prompt helper works across the flow" do
    ref = create(:reference_image, :analyzed, selected_provider: nil)

    # Without selection, falls back to claude
    assert_equal "Japanese zen garden in autumn, red maple trees", ref.best_ai_prompt

    # After curator selects openai
    ref.update!(selected_provider: "openai")
    assert_equal "Tranquil Japanese garden, autumn foliage, koi pond", ref.best_ai_prompt
  end

  test "limited collection stock tracking with training pipeline" do
    limited = create(:collection, :limited, stock_remaining: 10)
    ref = create(:reference_image, :curated, collection: limited)

    generation = Generations::TrainingPipeline.call(
      reference_image: ref,
      user: @admin
    )

    design = generation.design
    assert_equal limited, design.collection

    # Stock decrements on purchase (simulated)
    limited.decrement_stock!
    assert_equal 9, limited.reload.stock_remaining
  end
end
