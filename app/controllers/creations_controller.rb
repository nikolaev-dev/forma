class CreationsController < ApplicationController
  def new
    @style = Style.published.find_by(slug: params[:style]) if params[:style].present?
    @categories = TagCategory.active.ordered.includes(:tags)
    @available_tags = Tag.available.order(:weight)
  end

  def create
    user_prompt = creation_params[:user_prompt].to_s.strip

    if user_prompt.blank?
      @style = Style.published.find_by(slug: creation_params[:style_slug]) if creation_params[:style_slug].present?
      @categories = TagCategory.active.ordered.includes(:tags)
      @available_tags = Tag.available.order(:weight)
      flash.now[:alert] = "Опишите, каким вы видите свой блокнот"
      render :new, status: :unprocessable_entity
      return
    end

    style = Style.published.find_by(slug: creation_params[:style_slug]) if creation_params[:style_slug].present?
    tags = creation_params[:tag_ids].present? ? Tag.available.where(id: creation_params[:tag_ids]) : []

    generation = Generations::Pipeline.call(
      user_prompt: user_prompt,
      style: style,
      tags: tags.to_a,
      user: current_user,
      anonymous_identity: current_user ? nil : current_anonymous_identity
    )

    redirect_to progress_creation_path(generation.design)
  end

  def show
    @design = Design.find(params[:id])
    redirect_to result_creation_path(@design)
  end

  def progress
    @design = Design.find(params[:id])
    @generation = @design.generations.order(created_at: :desc).first!

    if @generation.status.in?(%w[succeeded partial])
      redirect_to result_creation_path(@design)
    end
  end

  def result
    @design = Design.find(params[:id])
    @generation = @design.generations.order(created_at: :desc).first!
    @variants = @generation.generation_variants.where(status: "succeeded").order(:kind)

    if @variants.empty? && @generation.status == "failed"
      redirect_to new_creation_path, alert: "Генерация не удалась. Попробуйте ещё раз."
    end
  end

  private

  def creation_params
    params.require(:creation).permit(:user_prompt, :style_slug, tag_ids: [])
  end
end
