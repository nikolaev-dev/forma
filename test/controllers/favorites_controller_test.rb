require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "index redirects to login for guest" do
    get favorites_path
    assert_redirected_to root_path
  end

  test "index renders for authenticated user" do
    sign_in_as(@user)
    get favorites_path
    assert_response :success
  end

  test "index shows favorited designs" do
    sign_in_as(@user)
    design = create(:design, visibility: "public", title: "Мой любимый")
    create(:favorite, user: @user, design: design)

    get favorites_path
    assert_response :success
    assert_match "Мой любимый", response.body
  end

  test "index shows empty state when no favorites" do
    sign_in_as(@user)
    get favorites_path
    assert_response :success
    assert_match "Сохраняй дизайны", response.body
  end

  # toggle_favorite via DesignsController
  test "toggle_favorite adds to favorites" do
    sign_in_as(@user)
    design = create(:design, visibility: "public", slug: "test-fav")

    assert_difference "Favorite.count", 1 do
      post toggle_favorite_design_path("test-fav")
    end
  end

  test "toggle_favorite removes from favorites" do
    sign_in_as(@user)
    design = create(:design, visibility: "public", slug: "test-unfav")
    create(:favorite, user: @user, design: design)

    assert_difference "Favorite.count", -1 do
      post toggle_favorite_design_path("test-unfav")
    end
  end

  test "toggle_favorite requires auth" do
    design = create(:design, visibility: "public", slug: "test-no-auth")
    post toggle_favorite_design_path("test-no-auth")
    assert_redirected_to root_path
  end

  # rate via DesignsController
  test "rate creates rating" do
    sign_in_as(@user)
    design = create(:design, visibility: "public", slug: "test-rate")

    assert_difference "DesignRating.count", 1 do
      post rate_design_path("test-rate"), params: { score: 5 }
    end

    assert_equal 5, DesignRating.last.score
  end

  test "rate updates existing rating" do
    sign_in_as(@user)
    design = create(:design, visibility: "public", slug: "test-rerate")
    create(:design_rating, user: @user, design: design, score: 3)

    assert_no_difference "DesignRating.count" do
      post rate_design_path("test-rerate"), params: { score: 5 }
    end

    assert_equal 5, @user.design_ratings.find_by(design: design).score
  end
end
