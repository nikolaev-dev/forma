FactoryBot.define do
  factory :usage_counter do
    user
    anonymous_identity { nil }
    period { Date.current }
    generations_count { 0 }
  end
end
