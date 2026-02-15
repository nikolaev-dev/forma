require "test_helper"

class Generations::PromptComposerTest < ActiveSupport::TestCase
  test "composes prompt from user text only" do
    result = Generations::PromptComposer.call(user_prompt: "красивый блокнот")
    assert_includes result[:composed_prompt], "красивый блокнот"
    assert_includes result[:composed_prompt], "no logos"
    assert_empty result[:tags_used]
  end

  test "includes style prefix" do
    style = create(:style, generation_preset: { "style_prompt" => "minimal aesthetic" })
    result = Generations::PromptComposer.call(user_prompt: "блокнот", style: style)
    assert_includes result[:composed_prompt], "minimal aesthetic"
  end

  test "includes tag names" do
    tags = create_list(:tag, 2)
    result = Generations::PromptComposer.call(user_prompt: "блокнот", tags: tags)
    tags.each do |tag|
      assert_includes result[:composed_prompt], tag.name
    end
    assert_equal tags.map(&:slug).sort, result[:tags_used].sort
  end

  test "includes hidden tags" do
    hidden = create_list(:tag, 1, :hidden)
    result = Generations::PromptComposer.call(user_prompt: "блокнот", hidden_tags: hidden)
    assert_includes result[:composed_prompt], hidden.first.name
    assert_equal hidden.map(&:slug), result[:hidden_tags_used]
  end

  test "always applies policy suffix" do
    result = Generations::PromptComposer.call(user_prompt: "anything")
    assert_includes result[:composed_prompt], "no logos"
    assert_includes result[:composed_prompt], "no copyrighted characters"
    assert_includes result[:policy_applied], "no_logos"
  end

  test "falls back to style name if no style_prompt" do
    style = create(:style, name: "Ар-деко", generation_preset: {})
    result = Generations::PromptComposer.call(user_prompt: "блокнот", style: style)
    assert_includes result[:composed_prompt], "Ар-деко"
  end
end
