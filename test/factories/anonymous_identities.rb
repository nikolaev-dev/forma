FactoryBot.define do
  factory :anonymous_identity do
    anon_token_hash { Digest::SHA256.hexdigest(SecureRandom.urlsafe_base64(32)) }
  end
end
