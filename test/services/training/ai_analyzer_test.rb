require "test_helper"
require "net/http"

class Training::AiAnalyzerTest < ActiveSupport::TestCase
  setup do
    @image_data = "fake image binary data"
    @content_type = "image/jpeg"

    @analysis_result = {
      "description" => "Обложка с японским садом",
      "base_prompt" => "Japanese zen garden in autumn",
      "suggested_tags" => %w[japan autumn nature],
      "mood" => "serene",
      "dominant_colors" => ["#8B0000", "#FFD700"],
      "visual_style" => "watercolor",
      "complexity" => "high"
    }
  end

  test "raises for unknown provider" do
    assert_raises(ArgumentError) do
      Training::AiAnalyzer.call(
        image_data: @image_data,
        content_type: @content_type,
        provider: "unknown"
      )
    end
  end

  test "claude provider calls Anthropic API and returns parsed result" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")

    mock_response = mock("response")
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    mock_response.stubs(:body).returns({
      "content" => [{ "text" => @analysis_result.to_json }]
    }.to_json)

    Net::HTTP.any_instance.stubs(:request).returns(mock_response)

    result = Training::AiAnalyzer.call(
      image_data: @image_data,
      content_type: @content_type,
      provider: "claude"
    )

    assert_equal "Japanese zen garden in autumn", result["base_prompt"]
    assert_equal %w[japan autumn nature], result["suggested_tags"]
  end

  test "openai provider calls OpenAI API and returns parsed result" do
    Rails.application.credentials.stubs(:dig).with(:openai, :api_key).returns("test-key")

    mock_response = mock("response")
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    mock_response.stubs(:body).returns({
      "choices" => [{ "message" => { "content" => @analysis_result.to_json } }]
    }.to_json)

    Net::HTTP.any_instance.stubs(:request).returns(mock_response)

    result = Training::AiAnalyzer.call(
      image_data: @image_data,
      content_type: @content_type,
      provider: "openai"
    )

    assert_equal "Japanese zen garden in autumn", result["base_prompt"]
  end

  test "strips markdown code fences from response" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")

    json_with_fences = "```json\n#{@analysis_result.to_json}\n```"

    mock_response = mock("response")
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    mock_response.stubs(:body).returns({
      "content" => [{ "text" => json_with_fences }]
    }.to_json)

    Net::HTTP.any_instance.stubs(:request).returns(mock_response)

    result = Training::AiAnalyzer.call(
      image_data: @image_data,
      content_type: @content_type,
      provider: "claude"
    )

    assert_equal "serene", result["mood"]
  end

  test "raises AnalysisError on API failure" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")

    mock_response = mock("response")
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(false)
    mock_response.stubs(:code).returns("500")
    mock_response.stubs(:body).returns("Internal Server Error")

    Net::HTTP.any_instance.stubs(:request).returns(mock_response)

    assert_raises(Training::AiAnalyzer::AnalysisError) do
      Training::AiAnalyzer.call(
        image_data: @image_data,
        content_type: @content_type,
        provider: "claude"
      )
    end
  end

  test "raises AnalysisError when API key not configured" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns(nil)

    assert_raises(Training::AiAnalyzer::AnalysisError) do
      Training::AiAnalyzer.call(
        image_data: @image_data,
        content_type: @content_type,
        provider: "claude"
      )
    end
  end

  test "raises AnalysisError on timeout" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")

    Net::HTTP.any_instance.stubs(:request).raises(Net::ReadTimeout)

    assert_raises(Training::AiAnalyzer::AnalysisError) do
      Training::AiAnalyzer.call(
        image_data: @image_data,
        content_type: @content_type,
        provider: "claude"
      )
    end
  end

  test "raises AnalysisError on invalid JSON in AI response" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")

    mock_response = mock("response")
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    mock_response.stubs(:body).returns({
      "content" => [{ "text" => "not valid json at all" }]
    }.to_json)

    Net::HTTP.any_instance.stubs(:request).returns(mock_response)

    assert_raises(Training::AiAnalyzer::AnalysisError) do
      Training::AiAnalyzer.call(
        image_data: @image_data,
        content_type: @content_type,
        provider: "claude"
      )
    end
  end
end
