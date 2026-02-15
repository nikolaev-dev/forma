module Admin
  class StylesController < BaseController
    before_action :set_style, only: [:edit, :update, :destroy, :publish, :hide]

    def index
      @styles = Style.order(:position, :name)
      @styles = @styles.where(status: params[:status]) if params[:status].present?
      @styles = @styles.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    end

    def new
      @style = Style.new
      @tags = Tag.order(:name)
    end

    def create
      @style = Style.new(style_params)

      if @style.save
        sync_tags
        audit!(action: "style.create", record: @style, after: @style.attributes)
        redirect_to admin_styles_path, notice: "Стиль \"#{@style.name}\" создан"
      else
        @tags = Tag.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @tags = Tag.order(:name)
      @selected_tag_ids = @style.style_tags.pluck(:tag_id)
    end

    def update
      before_attrs = @style.attributes.dup
      if @style.update(style_params)
        sync_tags
        audit!(action: "style.update", record: @style, before: before_attrs, after: @style.attributes)
        redirect_to admin_styles_path, notice: "Стиль \"#{@style.name}\" обновлён"
      else
        @tags = Tag.order(:name)
        @selected_tag_ids = @style.style_tags.pluck(:tag_id)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      audit!(action: "style.delete", record: @style, before: @style.attributes)
      @style.destroy!
      redirect_to admin_styles_path, notice: "Стиль удалён"
    end

    def publish
      before_status = @style.status
      @style.update!(status: "published")
      audit!(action: "style.publish", record: @style, before: { status: before_status }, after: { status: "published" })
      redirect_to admin_styles_path, notice: "Стиль \"#{@style.name}\" опубликован"
    end

    def hide
      before_status = @style.status
      @style.update!(status: "hidden")
      audit!(action: "style.hide", record: @style, before: { status: before_status }, after: { status: "hidden" })
      redirect_to admin_styles_path, notice: "Стиль \"#{@style.name}\" скрыт"
    end

    private

    def set_style
      @style = Style.find(params[:id])
    end

    def style_params
      params.require(:style).permit(:name, :slug, :description, :status, :position, :cover_image, gallery_images: [],
                                    generation_preset: {})
    end

    def sync_tags
      return unless params[:tag_ids]

      tag_ids = Array(params[:tag_ids]).map(&:to_i).reject(&:zero?)
      existing_ids = @style.style_tags.pluck(:tag_id)

      # Add new
      (tag_ids - existing_ids).each do |tag_id|
        @style.style_tags.create!(tag_id: tag_id)
      end

      # Remove old
      @style.style_tags.where(tag_id: existing_ids - tag_ids).destroy_all
    end
  end
end
