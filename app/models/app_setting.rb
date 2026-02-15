class AppSetting < ApplicationRecord
  belongs_to :updated_by_user, class_name: "User", optional: true

  validates :key, presence: true, uniqueness: true

  def self.[](key)
    find_by(key: key)&.value
  end

  def self.set(key, value, user: nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value
    setting.updated_by_user = user
    setting.save!
    setting
  end
end
