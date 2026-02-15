FactoryBot.define do
  factory :order_file do
    order
    file_type { "cover_print_pdf" }
    status { "created" }
  end
end
