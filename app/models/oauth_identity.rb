class OauthIdentity < ApplicationRecord
  belongs_to :user

  encrypts :access_token, deterministic: false
  encrypts :refresh_token, deterministic: false

  enum :provider, {
    vk: "vk",
    yandex: "yandex",
    tbank: "tbank",
    alfa: "alfa",
    google: "google"
  }

  validates :provider, presence: true
  validates :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
end
