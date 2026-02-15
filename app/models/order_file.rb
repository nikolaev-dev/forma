class OrderFile < ApplicationRecord
  belongs_to :order

  has_one_attached :file

  enum :file_type, {
    cover_print_pdf: "cover_print_pdf",
    inner_print_pdf: "inner_print_pdf",
    dna_card_pdf: "dna_card_pdf",
    packing_slip_pdf: "packing_slip_pdf",
    preview_pack_zip: "preview_pack_zip"
  }, prefix: true

  enum :status, {
    created: "created",
    rendering: "rendering",
    ready: "ready",
    failed: "failed"
  }, prefix: true

  validates :file_type, presence: true
  validates :status, presence: true

  def start_rendering!
    update!(status: "rendering")
  end

  def finish!
    update!(status: "ready")
  end

  def fail_rendering!
    update!(status: "failed")
  end
end
