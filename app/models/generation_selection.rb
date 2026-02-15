class GenerationSelection < ApplicationRecord
  belongs_to :generation
  belongs_to :generation_variant
  belongs_to :user, optional: true
  belongs_to :anonymous_identity, optional: true
end
