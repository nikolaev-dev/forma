require "test_helper"

class AnonymousIdentityTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:anonymous_identity).valid?
  end

  test "invalid without anon_token_hash" do
    assert_not build(:anonymous_identity, anon_token_hash: nil).valid?
  end

  test "anon_token_hash must be unique" do
    hash = Digest::SHA256.hexdigest("token")
    create(:anonymous_identity, anon_token_hash: hash)
    assert_not build(:anonymous_identity, anon_token_hash: hash).valid?
  end
end
