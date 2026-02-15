require "test_helper"

class TrainingBatchTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:training_batch).valid?
  end

  test "invalid without name" do
    assert_not build(:training_batch, name: nil).valid?
  end

  test "status enum uses string values" do
    batch = create(:training_batch, status: "uploaded")
    raw = TrainingBatch.connection.select_value("SELECT status FROM training_batches WHERE id = #{batch.id}")
    assert_equal "uploaded", raw
  end

  test "belongs to created_by_user" do
    user = create(:user, role: "admin")
    batch = create(:training_batch, created_by_user: user)
    assert_equal user, batch.created_by_user
  end

  test "has many reference_images" do
    batch = create(:training_batch)
    ref = create(:reference_image, training_batch: batch)
    assert_includes batch.reference_images, ref
  end

  test "destroys reference_images on destroy" do
    batch = create(:training_batch)
    ref = create(:reference_image, training_batch: batch)
    batch.destroy!
    assert_not ReferenceImage.exists?(ref.id)
  end

  test "start_processing! transitions from uploaded to processing" do
    batch = create(:training_batch, status: "uploaded")
    batch.start_processing!
    assert_equal "processing", batch.status
  end

  test "complete! transitions from processing to completed" do
    batch = create(:training_batch, status: "processing")
    batch.complete!
    assert_equal "completed", batch.status
  end

  test "start_processing! raises from completed" do
    batch = create(:training_batch, status: "completed")
    assert_raises(TrainingBatch::InvalidTransition) { batch.start_processing! }
  end

  test "complete! raises from uploaded" do
    batch = create(:training_batch, status: "uploaded")
    assert_raises(TrainingBatch::InvalidTransition) { batch.complete! }
  end

  test "update_images_count! counts reference images" do
    batch = create(:training_batch)
    create_list(:reference_image, 3, training_batch: batch)
    batch.update_images_count!
    assert_equal 3, batch.images_count
  end
end
