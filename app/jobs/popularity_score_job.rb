class PopularityScoreJob < ApplicationJob
  queue_as :default

  # Weights for popularity formula (configurable via AppSetting)
  DEFAULT_WEIGHTS = {
    "rating_weight" => 1.0,
    "favorite_weight" => 2.0,
    "purchase_weight" => 5.0,
    "remix_weight" => 3.0
  }.freeze

  def perform
    weights = load_weights

    Design.published.moderated.find_each do |design|
      score = calculate_score(design, weights)
      design.update_column(:popularity_score, score.round(4))
    end
  end

  private

  def load_weights
    setting = AppSetting["popularity_weights"]
    if setting.is_a?(Hash)
      DEFAULT_WEIGHTS.merge(setting)
    else
      DEFAULT_WEIGHTS
    end
  end

  def calculate_score(design, weights)
    avg_rating = design.design_ratings.average(:score)&.to_f || 0
    rating_count = design.design_ratings.count
    favorites_count = design.favorites.count
    purchases_count = OrderItem.where(design: design).joins(:order).where(orders: { status: %w[paid in_production shipped delivered] }).count
    remix_count = design.remixes.published.count

    (avg_rating * rating_count * weights["rating_weight"]) +
      (favorites_count * weights["favorite_weight"]) +
      (purchases_count * weights["purchase_weight"]) +
      (remix_count * weights["remix_weight"])
  end
end
