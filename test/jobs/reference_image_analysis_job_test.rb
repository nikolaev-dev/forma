require "test_helper"

class ReferenceImageAnalysisJobTest < ActiveSupport::TestCase
  setup do
    @batch = create(:training_batch)
    @ref = create(:reference_image, :with_image, training_batch: @batch, status: "analyzing")

    @analysis_result = {
      "description" => "Обложка с японским садом",
      "base_prompt" => "Japanese zen garden in autumn",
      "suggested_tags" => %w[japan autumn],
      "mood" => "serene",
      "dominant_colors" => [ "#8B0000" ],
      "visual_style" => "watercolor",
      "complexity" => "high"
    }
  end

  test "stores claude analysis result" do
    Training::AiAnalyzer.stubs(:call).returns(@analysis_result)

    ReferenceImageAnalysisJob.new.perform(@ref.id, "claude")

    @ref.reload
    assert_equal "Japanese zen garden in autumn", @ref.ai_analysis_claude["base_prompt"]
  end

  test "stores openai analysis result" do
    Training::AiAnalyzer.stubs(:call).returns(@analysis_result)

    ReferenceImageAnalysisJob.new.perform(@ref.id, "openai")

    @ref.reload
    assert_equal "Japanese zen garden in autumn", @ref.ai_analysis_openai["base_prompt"]
  end

  test "completes analysis when both providers done" do
    # First, set claude analysis
    @ref.update!(ai_analysis_claude: @analysis_result)

    # Now run openai analysis
    Training::AiAnalyzer.stubs(:call).returns(@analysis_result)
    ReferenceImageAnalysisJob.new.perform(@ref.id, "openai")

    @ref.reload
    assert_equal "analyzed", @ref.status
  end

  test "does not complete analysis when only one provider done" do
    Training::AiAnalyzer.stubs(:call).returns(@analysis_result)

    ReferenceImageAnalysisJob.new.perform(@ref.id, "claude")

    @ref.reload
    assert_equal "analyzing", @ref.status
  end

  test "skips if already analyzed for provider (idempotent)" do
    @ref.update!(ai_analysis_claude: @analysis_result)

    Training::AiAnalyzer.expects(:call).never

    ReferenceImageAnalysisJob.new.perform(@ref.id, "claude")
  end

  test "enqueues on training queue" do
    assert_equal "training", ReferenceImageAnalysisJob.new.queue_name
  end
end
