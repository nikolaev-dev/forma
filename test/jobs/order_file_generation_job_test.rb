require "test_helper"

class OrderFileGenerationJobTest < ActiveSupport::TestCase
  test "creates order_file records for paid order" do
    order = create(:order, :paid)

    assert_difference "OrderFile.count", 3 do
      OrderFileGenerationJob.perform_now(order.id)
    end

    file_types = order.order_files.pluck(:file_type)
    assert_includes file_types, "cover_print_pdf"
    assert_includes file_types, "inner_print_pdf"
    assert_includes file_types, "dna_card_pdf"
  end

  test "sets order_files status to created" do
    order = create(:order, :paid)
    OrderFileGenerationJob.perform_now(order.id)

    order.order_files.each do |of|
      assert_equal "created", of.status
    end
  end

  test "does not duplicate files on re-run" do
    order = create(:order, :paid)
    OrderFileGenerationJob.perform_now(order.id)

    assert_no_difference "OrderFile.count" do
      OrderFileGenerationJob.perform_now(order.id)
    end
  end
end
