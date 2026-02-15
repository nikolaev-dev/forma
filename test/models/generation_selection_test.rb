require "test_helper"

class GenerationSelectionTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:generation_selection).valid?
  end

  test "belongs to generation" do
    selection = create(:generation_selection)
    assert_instance_of Generation, selection.generation
  end

  test "belongs to generation_variant" do
    selection = create(:generation_selection)
    assert_instance_of GenerationVariant, selection.generation_variant
  end

  test "user is optional" do
    assert build(:generation_selection, user: nil).valid?
  end

  test "anonymous_identity is optional" do
    assert build(:generation_selection, anonymous_identity: nil).valid?
  end

  test "can associate with user" do
    user = create(:user)
    selection = create(:generation_selection, user: user)
    assert_equal user, selection.user
  end
end
