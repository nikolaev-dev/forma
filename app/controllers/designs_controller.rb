class DesignsController < ApplicationController
  before_action :set_design, only: [:show, :remix, :toggle_favorite, :rate]
  before_action :require_auth, only: [:toggle_favorite, :rate]

  # S7: public design page
  def show
    @generation = @design.generations.where(status: %w[succeeded partial]).order(created_at: :desc).first
    @variants = @generation&.generation_variants&.where(status: "succeeded")&.order(:kind) || []
    @remixes = @design.remixes.published.moderated.order(created_at: :desc).limit(10)
    @is_favorited = current_user && current_user.favorites.exists?(design: @design)
    @average_rating = DesignRating.average_for(@design)
  end

  # POST /designs/:id/remix
  def remix
    user_prompt = params[:user_prompt].to_s.strip
    user_prompt = @design.base_prompt if user_prompt.blank?

    begin
      generation = Generations::Pipeline.call(
        user_prompt: user_prompt,
        style: @design.style,
        tags: @design.tags.to_a,
        user: current_user,
        anonymous_identity: current_user ? nil : current_anonymous_identity,
        source: "remix",
        ip: request.remote_ip
      )

      # Set source_design_id on the newly created design
      generation.design.update!(source_design_id: @design.id)

      redirect_to progress_creation_path(generation.design)
    rescue Generations::Pipeline::LimitExceeded
      redirect_to limit_reached_generation_passes_path, alert: "Дневной лимит генераций исчерпан"
    rescue Generations::Pipeline::RateLimited
      redirect_to design_path(@design.slug || @design.hashid), alert: "Слишком много запросов. Подождите минуту."
    end
  end

  # POST /designs/:id/toggle_favorite
  def toggle_favorite
    favorite = current_user.favorites.find_by(design: @design)
    if favorite
      favorite.destroy!
      redirect_back fallback_location: design_path(@design.slug || @design.hashid), notice: "Удалено из избранного"
    else
      current_user.favorites.create!(design: @design)
      redirect_back fallback_location: design_path(@design.slug || @design.hashid), notice: "Добавлено в избранное"
    end
  end

  # POST /designs/:id/rate
  def rate
    score = params[:score].to_i
    rating = current_user.design_ratings.find_or_initialize_by(design: @design, source: "user")
    rating.score = score
    rating.save!
    redirect_back fallback_location: design_path(@design.slug || @design.hashid), notice: "Оценка сохранена"
  end

  private

  def set_design
    @design = Design.visible.moderated.find_by(slug: params[:id])
    return if @design

    # Fallback: try hashid
    decoded = Design.decode_id(params[:id])
    @design = Design.visible.moderated.find_by(id: decoded) if decoded
    raise ActiveRecord::RecordNotFound, "Design not found" unless @design
  end
end
