require "test_helper"

class TrainingBatchAnalysisJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "transitions batch to processing and enqueues analysis jobs" do
    batch = create(:training_batch, status: "uploaded")
    ref1 = create(:reference_image, :with_image, training_batch: batch)
    ref2 = create(:reference_image, :with_image, training_batch: batch)

    assert_enqueued_jobs 4, only: ReferenceImageAnalysisJob do
      TrainingBatchAnalysisJob.new.perform(batch.id)
    end

    batch.reload
    assert_equal "processing", batch.status

    ref1.reload
    ref2.reload
    assert_equal "analyzing", ref1.status
    assert_equal "analyzing", ref2.status
  end

  test "skips non-uploaded batches" do
    batch = create(:training_batch, status: "processing")

    assert_no_enqueued_jobs only: ReferenceImageAnalysisJob do
      TrainingBatchAnalysisJob.new.perform(batch.id)
    end

    assert_equal "processing", batch.status
  end

  test "only processes pending_analysis images" do
    batch = create(:training_batch, status: "uploaded")
    create(:reference_image, :with_image, training_batch: batch, status: "uploaded")
    create(:reference_image, training_batch: batch, status: "analyzing")

    assert_enqueued_jobs 2, only: ReferenceImageAnalysisJob do
      TrainingBatchAnalysisJob.new.perform(batch.id)
    end
  end

  test "enqueues on training queue" do
    assert_equal "training", TrainingBatchAnalysisJob.new.queue_name
  end
end
