FactoryBot.define do
  factory :audit_log do
    actor_user factory: :user
    action { "tag.create" }
  end
end
