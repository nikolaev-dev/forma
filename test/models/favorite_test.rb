require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @design = create(:design, visibility: "public")
  end

  test "valid with user and design" do
    fav = build(:favorite, user: @user, design: @design)
    assert fav.valid?
  end

  test "requires user" do
    fav = build(:favorite, user: nil, design: @design)
    assert_not fav.valid?
  end

  test "requires design" do
    fav = build(:favorite, user: @user, design: nil)
    assert_not fav.valid?
  end

  test "unique constraint on user + design" do
    create(:favorite, user: @user, design: @design)
    duplicate = build(:favorite, user: @user, design: @design)
    assert_not duplicate.valid?
  end

  test "same user can favorite different designs" do
    other_design = create(:design, visibility: "public")
    create(:favorite, user: @user, design: @design)
    fav = build(:favorite, user: @user, design: other_design)
    assert fav.valid?
  end

  test "different users can favorite same design" do
    other_user = create(:user)
    create(:favorite, user: @user, design: @design)
    fav = build(:favorite, user: other_user, design: @design)
    assert fav.valid?
  end
end
