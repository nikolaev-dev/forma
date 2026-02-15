FactoryBot.define do
  factory :reference_image do
    training_batch
    status { "uploaded" }

    trait :with_image do
      after(:build) do |ref|
        ref.original_image.attach(
          io: StringIO.new("fake image data"),
          filename: "reference.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :analyzed do
      status { "analyzed" }
      ai_analysis_claude do
        {
          "description" => "Japanese zen garden",
          "base_prompt" => "Japanese zen garden in autumn, red maple trees",
          "suggested_tags" => %w[japan autumn nature],
          "mood" => "serene",
          "dominant_colors" => [ "#8B0000", "#FFD700" ],
          "visual_style" => "watercolor",
          "complexity" => "high"
        }
      end
      ai_analysis_openai do
        {
          "description" => "A tranquil Japanese garden scene",
          "base_prompt" => "Tranquil Japanese garden, autumn foliage, koi pond",
          "suggested_tags" => %w[japan autumn garden],
          "mood" => "peaceful",
          "dominant_colors" => [ "#8B0000", "#2F4F4F" ],
          "visual_style" => "illustration",
          "complexity" => "medium"
        }
      end
    end

    trait :curated do
      analyzed
      status { "curated" }
      selected_provider { "claude" }
      curated_prompt { "Japanese zen garden in autumn, red maple trees reflecting in koi pond" }
    end
  end
end
