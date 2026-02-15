require "test_helper"

class ReferenceImageTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:reference_image).valid?
  end

  test "status enum uses string values" do
    ref = create(:reference_image, status: "uploaded")
    raw = ReferenceImage.connection.select_value("SELECT status FROM reference_images WHERE id = #{ref.id}")
    assert_equal "uploaded", raw
  end

  test "belongs to training_batch" do
    batch = create(:training_batch)
    ref = create(:reference_image, training_batch: batch)
    assert_equal batch, ref.training_batch
  end

  test "optional collection association" do
    collection = create(:collection)
    ref = create(:reference_image, collection: collection)
    assert_equal collection, ref.collection
  end

  test "optional design association" do
    design = create(:design)
    ref = create(:reference_image, design: design)
    assert_equal design, ref.design
  end

  test "selected_provider validates inclusion" do
    assert build(:reference_image, selected_provider: "claude").valid?
    assert build(:reference_image, selected_provider: "openai").valid?
    assert build(:reference_image, selected_provider: nil).valid?
    assert_not build(:reference_image, selected_provider: "invalid").valid?
  end

  # State machine transitions

  test "start_analysis! transitions from uploaded to analyzing" do
    ref = create(:reference_image, status: "uploaded")
    ref.start_analysis!
    assert_equal "analyzing", ref.status
  end

  test "complete_analysis! transitions from analyzing to analyzed" do
    ref = create(:reference_image, status: "analyzing")
    ref.complete_analysis!
    assert_equal "analyzed", ref.status
  end

  test "curate! transitions from analyzed to curated with attributes" do
    collection = create(:collection)
    ref = create(:reference_image, :analyzed)
    ref.curate!(
      prompt: "Curated prompt text",
      provider: "claude",
      collection: collection,
      notes: "Good quality"
    )
    assert_equal "curated", ref.status
    assert_equal "Curated prompt text", ref.curated_prompt
    assert_equal "claude", ref.selected_provider
    assert_equal collection, ref.collection
    assert_equal "Good quality", ref.curator_notes
  end

  test "curate! raises from uploaded" do
    ref = create(:reference_image, status: "uploaded")
    assert_raises(ReferenceImage::InvalidTransition) do
      ref.curate!(prompt: "test")
    end
  end

  test "mark_generated! transitions from curated to generated" do
    design = create(:design)
    ref = create(:reference_image, :curated)
    ref.mark_generated!(design: design)
    assert_equal "generated", ref.status
    assert_equal design, ref.design
  end

  test "publish! transitions from generated to published" do
    ref = create(:reference_image, status: "generated")
    ref.publish!
    assert_equal "published", ref.status
  end

  test "reject! from analyzed" do
    ref = create(:reference_image, :analyzed)
    ref.reject!(notes: "Low quality")
    assert_equal "rejected", ref.status
    assert_equal "Low quality", ref.curator_notes
  end

  test "reject! from curated" do
    ref = create(:reference_image, :curated)
    ref.reject!(notes: "Changed mind")
    assert_equal "rejected", ref.status
  end

  test "reject! from generated" do
    ref = create(:reference_image, status: "generated")
    ref.reject!
    assert_equal "rejected", ref.status
  end

  test "reject! raises from uploaded" do
    ref = create(:reference_image, status: "uploaded")
    assert_raises(ReferenceImage::InvalidTransition) { ref.reject! }
  end

  test "reject! raises from published" do
    ref = create(:reference_image, status: "published")
    assert_raises(ReferenceImage::InvalidTransition) { ref.reject! }
  end

  # Scopes

  test "pending_analysis scope" do
    create(:reference_image, status: "uploaded")
    create(:reference_image, status: "analyzing")
    assert_equal 1, ReferenceImage.pending_analysis.count
  end

  test "pending_curation scope" do
    create(:reference_image, :analyzed)
    create(:reference_image, status: "uploaded")
    assert_equal 1, ReferenceImage.pending_curation.count
  end

  test "pending_generation scope" do
    create(:reference_image, :curated)
    create(:reference_image, status: "uploaded")
    assert_equal 1, ReferenceImage.pending_generation.count
  end

  # best_ai_prompt

  test "best_ai_prompt returns claude prompt when selected" do
    ref = build(:reference_image, :analyzed, selected_provider: "claude")
    assert_equal "Japanese zen garden in autumn, red maple trees", ref.best_ai_prompt
  end

  test "best_ai_prompt returns openai prompt when selected" do
    ref = build(:reference_image, :analyzed, selected_provider: "openai")
    assert_equal "Tranquil Japanese garden, autumn foliage, koi pond", ref.best_ai_prompt
  end

  test "best_ai_prompt falls back to claude when no provider selected" do
    ref = build(:reference_image, :analyzed, selected_provider: nil)
    assert_equal "Japanese zen garden in autumn, red maple trees", ref.best_ai_prompt
  end

  test "best_ai_prompt falls back to openai when claude empty" do
    ref = build(:reference_image,
      ai_analysis_claude: {},
      ai_analysis_openai: { "base_prompt" => "openai prompt" },
      selected_provider: nil)
    assert_equal "openai prompt", ref.best_ai_prompt
  end

  test "counter_cache updates training_batch images_count" do
    batch = create(:training_batch)
    assert_equal 0, batch.images_count

    create(:reference_image, training_batch: batch)
    assert_equal 1, batch.reload.images_count
  end
end
