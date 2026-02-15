require "test_helper"

class Generations::ProviderInterfaceTest < ActiveSupport::TestCase
  setup do
    @provider = Generations::ProviderInterface.new
  end

  test "create_generation raises NotImplementedError" do
    assert_raises(NotImplementedError) { @provider.create_generation({}) }
  end

  test "get_status raises NotImplementedError" do
    assert_raises(NotImplementedError) { @provider.get_status("job-1") }
  end

  test "fetch_result raises NotImplementedError" do
    assert_raises(NotImplementedError) { @provider.fetch_result("job-1") }
  end

  test "cancel raises NotImplementedError" do
    assert_raises(NotImplementedError) { @provider.cancel("job-1") }
  end
end
