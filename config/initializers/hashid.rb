Hashid::Rails.configure do |config|
  config.salt = Rails.application.credentials.dig(:hashid, :salt) || "forma-hashid-salt"
  config.min_hash_length = 6
  config.alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
end
