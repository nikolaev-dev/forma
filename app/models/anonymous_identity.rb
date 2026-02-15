class AnonymousIdentity < ApplicationRecord
  validates :anon_token_hash, presence: true, uniqueness: true
end
