require "test_helper"

class DesignRatingTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @design = create(:design, visibility: "public")
  end

  test "valid with required fields" do
    rating = build(:design_rating, user: @user, design: @design, score: 4)
    assert rating.valid?
  end

  test "requires design" do
    rating = build(:design_rating, design: nil, user: @user)
    assert_not rating.valid?
  end

  test "requires score" do
    rating = build(:design_rating, user: @user, design: @design, score: nil)
    assert_not rating.valid?
  end

  test "score must be between 1 and 5" do
    assert_not build(:design_rating, user: @user, design: @design, score: 0).valid?
    assert_not build(:design_rating, user: @user, design: @design, score: 6).valid?
    assert build(:design_rating, user: @user, design: @design, score: 1).valid?
    assert build(:design_rating, user: @user, design: @design, score: 5).valid?
  end

  test "unique user rating per design" do
    create(:design_rating, user: @user, design: @design, score: 4)
    duplicate = build(:design_rating, user: @user, design: @design, score: 3)
    assert_not duplicate.valid?
  end

  test "admin rating not constrained by user uniqueness" do
    create(:design_rating, user: @user, design: @design, source: "user", score: 4)
    admin_rating = build(:design_rating, user: @user, design: @design, source: "admin", score: 5)
    assert admin_rating.valid?
  end

  test "default source is user" do
    rating = DesignRating.new(user: @user, design: @design, score: 3)
    assert_equal "user", rating.source
  end

  test "average_for returns average score for design" do
    create(:design_rating, design: @design, score: 5)
    other_user = create(:user)
    create(:design_rating, design: @design, user: other_user, score: 3)

    assert_equal 4.0, DesignRating.average_for(@design)
  end

  test "average_for returns nil when no ratings" do
    assert_nil DesignRating.average_for(@design)
  end
end
