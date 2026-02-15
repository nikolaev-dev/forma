class User < ApplicationRecord
  include Hashid::Rails

  has_many :oauth_identities, dependent: :destroy

  enum :role, {
    user: "user",
    creator: "creator",
    moderator: "moderator",
    admin: "admin"
  }

  enum :status, {
    active: "active",
    blocked: "blocked",
    deleted: "deleted"
  }, prefix: true

  validates :role, presence: true
  validates :status, presence: true
  validates :locale, presence: true
  validates :email, uniqueness: { allow_nil: true }
  validates :phone, uniqueness: { allow_nil: true }
end
