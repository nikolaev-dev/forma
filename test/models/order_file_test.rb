require "test_helper"

class OrderFileTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:order_file).valid?
  end

  test "invalid without order" do
    assert_not build(:order_file, order: nil).valid?
  end

  test "invalid without file_type" do
    assert_not build(:order_file, file_type: nil).valid?
  end

  test "file_type enum uses string values" do
    of = create(:order_file, file_type: "dna_card_pdf")
    raw = OrderFile.connection.select_value("SELECT file_type FROM order_files WHERE id = #{of.id}")
    assert_equal "dna_card_pdf", raw
  end

  test "status enum uses string values" do
    of = create(:order_file, status: "rendering")
    raw = OrderFile.connection.select_value("SELECT status FROM order_files WHERE id = #{of.id}")
    assert_equal "rendering", raw
  end

  test "start_rendering! transitions created to rendering" do
    of = create(:order_file, status: "created")
    of.start_rendering!
    assert_equal "rendering", of.status
  end

  test "finish! transitions rendering to ready" do
    of = create(:order_file, status: "rendering")
    of.finish!
    assert_equal "ready", of.status
  end

  test "fail_rendering! transitions rendering to failed" do
    of = create(:order_file, status: "rendering")
    of.fail_rendering!
    assert_equal "failed", of.status
  end
end
