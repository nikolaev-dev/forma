module Training
  class AiAnalyzer
    class AnalysisError < StandardError; end

    CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
    OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"

    ANALYSIS_PROMPT = <<~PROMPT
      Analyze this notebook cover reference image. Return a JSON object with exactly these fields:
      - description: Brief description in Russian (1-2 sentences)
      - base_prompt: English prompt for generating a similar notebook cover design (detailed, 1-2 sentences)
      - suggested_tags: Array of 3-6 English tag slugs (lowercase, hyphens)
      - mood: Single word describing the mood (English)
      - dominant_colors: Array of 2-4 hex color codes
      - visual_style: Style description (e.g. "watercolor", "photography", "digital art")
      - complexity: "low", "medium", or "high"

      Return ONLY valid JSON, no markdown formatting.
    PROMPT

    # @param image_data [String] binary image data
    # @param content_type [String] MIME type (e.g. "image/jpeg")
    # @param provider [String] "claude" or "openai"
    # @return [Hash] parsed analysis result
    def self.call(image_data:, content_type:, provider:)
      new(image_data:, content_type:, provider:).call
    end

    def initialize(image_data:, content_type:, provider:)
      @image_data = image_data
      @content_type = content_type
      @provider = provider
    end

    def call
      case @provider
      when "claude"
        analyze_with_claude
      when "openai"
        analyze_with_openai
      else
        raise ArgumentError, "Unknown provider: #{@provider}"
      end
    end

    private

    def analyze_with_claude
      api_key = Rails.application.credentials.dig(:anthropic, :api_key)
      raise AnalysisError, "Anthropic API key not configured" if api_key.blank?

      base64_image = Base64.strict_encode64(@image_data)

      body = {
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: @content_type,
                  data: base64_image
                }
              },
              { type: "text", text: ANALYSIS_PROMPT }
            ]
          }
        ]
      }.to_json

      response = http_post(
        CLAUDE_API_URL,
        body: body,
        headers: {
          "Content-Type" => "application/json",
          "x-api-key" => api_key,
          "anthropic-version" => "2023-06-01"
        }
      )

      parse_claude_response(response)
    end

    def analyze_with_openai
      api_key = Rails.application.credentials.dig(:openai, :api_key)
      raise AnalysisError, "OpenAI API key not configured" if api_key.blank?

      base64_image = Base64.strict_encode64(@image_data)

      body = {
        model: "gpt-4o",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: {
                  url: "data:#{@content_type};base64,#{base64_image}"
                }
              },
              { type: "text", text: ANALYSIS_PROMPT }
            ]
          }
        ]
      }.to_json

      response = http_post(
        OPENAI_API_URL,
        body: body,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{api_key}"
        }
      )

      parse_openai_response(response)
    end

    def http_post(url, body:, headers:)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = body

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise AnalysisError, "API returned #{response.code}: #{response.body.truncate(200)}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise AnalysisError, "Invalid JSON response: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise AnalysisError, "Request timeout: #{e.message}"
    rescue Errno::ECONNREFUSED, SocketError => e
      raise AnalysisError, "Connection error: #{e.message}"
    end

    def parse_claude_response(response)
      text = response.dig("content", 0, "text")
      raise AnalysisError, "Empty Claude response" if text.blank?
      parse_json_content(text)
    end

    def parse_openai_response(response)
      text = response.dig("choices", 0, "message", "content")
      raise AnalysisError, "Empty OpenAI response" if text.blank?
      parse_json_content(text)
    end

    def parse_json_content(text)
      # Strip markdown code fences if present
      cleaned = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
      JSON.parse(cleaned)
    rescue JSON::ParserError => e
      raise AnalysisError, "Failed to parse AI response as JSON: #{e.message}"
    end
  end
end
