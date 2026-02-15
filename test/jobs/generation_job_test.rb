require "test_helper"

class GenerationJobTest < ActiveSupport::TestCase
  setup do
    @generation = create(:generation, :with_variants, status: "created")
  end

  test "processes all variants and finishes generation as succeeded" do
    GenerationJob.new.perform(@generation.id)

    @generation.reload
    assert_equal "succeeded", @generation.status
    assert @generation.started_at.present?
    assert @generation.finished_at.present?

    @generation.generation_variants.each do |v|
      assert_equal "succeeded", v.status, "variant #{v.kind} should be succeeded"
      assert v.preview_image.attached?, "variant #{v.kind} should have preview_image"
    end
  end

  test "attaches PNG images to variants" do
    GenerationJob.new.perform(@generation.id)

    variant = @generation.generation_variants.find_by(kind: "main")
    blob = variant.preview_image.blob
    assert_equal "image/png", blob.content_type
    assert blob.byte_size > 0
  end

  test "skips canceled generation" do
    @generation.update!(status: "canceled")

    GenerationJob.new.perform(@generation.id)

    @generation.reload
    assert_equal "canceled", @generation.status
    assert_nil @generation.finished_at
    @generation.generation_variants.each do |v|
      assert_equal "created", v.status
    end
  end

  test "enqueues on generation queue" do
    assert_equal "generation", GenerationJob.new.queue_name
  end
end
