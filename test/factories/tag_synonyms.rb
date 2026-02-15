FactoryBot.define do
  factory :tag_synonym do
    tag
    phrase { Faker::Lorem.unique.word }
    normalized { nil } # set by before_validation
  end
end
