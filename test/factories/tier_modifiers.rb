FactoryBot.define do
  factory :tier_modifier do
    tier { "core" }
    prompt_modifier { "Test prompt modifier for core tier" }
    identity_elements { "Test identity elements" }
    negative_prompt { "cartoon, illustration, low resolution" }
    settings { { aspect_ratio: "2:3", lens: "50mm" } }

    trait :core do
      tier { "core" }
      prompt_modifier { "Coated paper wrap cover, matte lamination, flat printed wave, simple elastic band" }
      identity_elements { "Two plain ribbon bookmarks, one chamfered 45-degree top-right corner" }
    end

    trait :signature do
      tier { "signature" }
      prompt_modifier { "Soft-touch paper cover with visible matte texture, spot UV on wave area, blind embossed small logo" }
      identity_elements { "Blind embossed hexagonal badge, two ribbon bookmarks, one chamfered corner" }
    end

    trait :lux do
      tier { "lux" }
      prompt_modifier { "Real leather cover with visible natural grain, deep multi-level embossed wave, polished metal badge" }
      identity_elements { "Polished metal hexagonal badge, two ribbon bookmarks with hex metal tips" }
    end
  end
end
