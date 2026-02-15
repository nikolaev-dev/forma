require "test_helper"

class Orders::NumberGeneratorTest < ActiveSupport::TestCase
  test "generates order number in format FORMA-YYYY-NNNNNN" do
    number = Orders::NumberGenerator.call
    assert_match(/\AFORMA-\d{4}-\d{6}\z/, number)
  end

  test "includes current year" do
    number = Orders::NumberGenerator.call
    assert_includes number, Time.current.year.to_s
  end

  test "generates sequential numbers based on existing orders" do
    create(:order, order_number: "FORMA-#{Time.current.year}-000003", barcode_value: "BC-seq-1")
    next_number = Orders::NumberGenerator.call
    assert_equal "FORMA-#{Time.current.year}-000004", next_number
  end

  test "starts from 1 when no orders exist for current year" do
    number = Orders::NumberGenerator.call
    assert_equal "FORMA-#{Time.current.year}-000001", number
  end
end
