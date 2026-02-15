require "barby/barcode/code_128"
require "barby/outputter/png_outputter"

module Orders
  class BarcodeGenerator
    def self.call(order)
      barcode = Barby::Code128.new(order.barcode_value)
      Barby::PngOutputter.new(barcode).to_png(height: 60, margin: 5)
    end
  end
end
