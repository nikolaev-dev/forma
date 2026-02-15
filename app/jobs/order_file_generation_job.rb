class OrderFileGenerationJob < ApplicationJob
  queue_as :default

  FILE_TYPES = %w[cover_print_pdf inner_print_pdf dna_card_pdf].freeze

  def perform(order_id)
    order = Order.find(order_id)

    FILE_TYPES.each do |file_type|
      order.order_files.find_or_create_by!(file_type: file_type) do |of|
        of.status = "created"
      end
    end
  end
end
