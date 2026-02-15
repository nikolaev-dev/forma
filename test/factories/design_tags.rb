FactoryBot.define do
  factory :design_tag do
    design
    tag
    source { "user" }
  end
end
