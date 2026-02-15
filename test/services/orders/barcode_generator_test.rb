require "test_helper"

class Orders::BarcodeGeneratorTest < ActiveSupport::TestCase
  test "generates PNG blob from order" do
    order = create(:order)
    png = Orders::BarcodeGenerator.call(order)

    assert png.is_a?(String)
    assert png.bytesize > 0
    # PNG magic bytes
    assert_equal "\x89PNG".b, png[0..3]
  end

  test "uses barcode_value from order" do
    order = create(:order, barcode_value: "FORMA-2026-000042")
    png = Orders::BarcodeGenerator.call(order)
    assert png.present?
  end
end
