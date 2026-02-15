require "test_helper"

class Generations::Providers::TestProviderTest < ActiveSupport::TestCase
  setup do
    @provider = Generations::Providers::TestProvider.new
  end

  test "inherits from ProviderInterface" do
    assert_kind_of Generations::ProviderInterface, @provider
  end

  test "create_generation returns a job id starting with test-" do
    job_id = @provider.create_generation(prompt: "test")
    assert job_id.start_with?("test-")
    assert_equal 21, job_id.length # "test-" + 16 hex chars
  end

  test "get_status always returns succeeded" do
    assert_equal "succeeded", @provider.get_status("any-id")
  end

  test "fetch_result returns image data hash" do
    result = @provider.fetch_result("any-id")

    assert result[:image_data].present?
    assert_equal "image/png", result[:content_type]
    assert_equal "test", result[:metadata][:provider]
    assert result[:metadata][:generated_at].present?
  end

  test "fetch_result returns valid PNG data" do
    result = @provider.fetch_result("any-id")
    # PNG magic bytes
    assert result[:image_data].bytes[0..3] == [ 0x89, 0x50, 0x4E, 0x47 ]
  end

  test "cancel returns true" do
    assert_equal true, @provider.cancel("any-id")
  end
end
