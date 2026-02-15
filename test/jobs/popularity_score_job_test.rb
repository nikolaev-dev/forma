require "test_helper"

class PopularityScoreJobTest < ActiveSupport::TestCase
  test "recalculates popularity_score for public designs" do
    design = create(:design, visibility: "public", popularity_score: 0)

    # Add ratings
    user1 = create(:user)
    user2 = create(:user)
    create(:design_rating, design: design, user: user1, score: 5)
    create(:design_rating, design: design, user: user2, score: 4)

    # Add favorites
    create(:favorite, user: user1, design: design)
    create(:favorite, user: user2, design: design)

    # Add order (purchase = high weight)
    generation = create(:generation, design: design, status: "succeeded")
    sku = create(:notebook_sku)
    filling = create(:filling)
    order = create(:order, :paid)
    create(:order_item, order: order, design: design, notebook_sku: sku, filling: filling)

    PopularityScoreJob.perform_now

    design.reload
    assert design.popularity_score > 0, "Popularity score should be recalculated"
  end

  test "does not update private designs" do
    private_design = create(:design, visibility: "private", popularity_score: 0)
    user = create(:user)
    create(:design_rating, design: private_design, user: user, score: 5)

    PopularityScoreJob.perform_now

    assert_equal 0.0, private_design.reload.popularity_score.to_f
  end

  test "higher engagement produces higher score" do
    popular = create(:design, visibility: "public")
    unpopular = create(:design, visibility: "public")

    # Popular: many ratings and favorites
    5.times do
      u = create(:user)
      create(:design_rating, design: popular, user: u, score: 5)
      create(:favorite, user: u, design: popular)
    end

    # Unpopular: just one rating
    create(:design_rating, design: unpopular, score: 2)

    PopularityScoreJob.perform_now

    assert popular.reload.popularity_score > unpopular.reload.popularity_score
  end
end
