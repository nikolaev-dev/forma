class FavoritesController < ApplicationController
  before_action :require_auth

  # S14: favorites screen
  def index
    @favorites = current_user.favorites
      .includes(design: [ :style, :tags, generations: :generation_variants ])
      .order(created_at: :desc)
    @designs = @favorites.map(&:design)
  end
end
