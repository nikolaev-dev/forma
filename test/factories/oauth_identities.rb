FactoryBot.define do
  factory :oauth_identity do
    user
    provider { "google" }
    uid { SecureRandom.hex(10) }
    access_token { SecureRandom.hex(20) }
    raw_profile { { name: "Test User" } }
  end
end
