FactoryBot.define do
  factory :design_rating do
    design
    user
    source { "user" }
    score { 4 }
  end
end
