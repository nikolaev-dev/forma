FactoryBot.define do
  factory :app_setting do
    sequence(:key) { |n| "setting_#{n}" }
    value { { "value" => 42 } }
  end
end
