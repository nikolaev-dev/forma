module Admin
  class TagsController < BaseController
    before_action :set_tag, only: [:edit, :update, :destroy, :merge]

    def index
      @tags = Tag.includes(:tag_category).order(:name)
      @tags = @tags.where(tag_category_id: params[:category_id]) if params[:category_id].present?
      @tags = @tags.where(visibility: params[:visibility]) if params[:visibility].present?
      @tags = @tags.where(is_banned: true) if params[:banned] == "1"
      @tags = @tags.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      @categories = TagCategory.order(:position)
    end

    def new
      @tag = Tag.new
      @categories = TagCategory.order(:position)
    end

    def create
      @tag = Tag.new(tag_params)

      if @tag.save
        audit!(action: "tag.create", record: @tag, after: @tag.attributes)
        redirect_to admin_tags_path, notice: "Тег \"#{@tag.name}\" создан"
      else
        @categories = TagCategory.order(:position)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = TagCategory.order(:position)
    end

    def update
      before_attrs = @tag.attributes.dup
      if @tag.update(tag_params)
        audit!(action: "tag.update", record: @tag, before: before_attrs, after: @tag.attributes)
        redirect_to admin_tags_path, notice: "Тег \"#{@tag.name}\" обновлён"
      else
        @categories = TagCategory.order(:position)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      audit!(action: "tag.delete", record: @tag, before: @tag.attributes)
      @tag.destroy!
      redirect_to admin_tags_path, notice: "Тег удалён"
    end

    def import_csv
      file = params[:file]
      if file.blank?
        redirect_to admin_tags_path, alert: "Файл не выбран"
        return
      end

      stats = Tags::CsvImporter.call(file.path)
      audit!(action: "tag.import_csv", after: stats.except(:errors))
      notice = "Импорт: создано #{stats[:created]}, пропущено #{stats[:skipped]}"
      notice += ", ошибок #{stats[:errors].size}" if stats[:errors].any?
      redirect_to admin_tags_path, notice: notice
    end

    def merge
      target_tag = Tag.find(params[:target_tag_id])
      Tags::Merger.call(source: @tag, target: target_tag)
      audit!(action: "tag.merge", record: target_tag,
             before: { merged_tag_id: @tag.id, merged_tag_name: @tag.name },
             after: { target_tag_id: target_tag.id })
      redirect_to admin_tags_path, notice: "Тег \"#{@tag.name}\" объединён с \"#{target_tag.name}\""
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :slug, :tag_category_id, :visibility, :kind, :weight, :is_banned, :banned_reason)
    end
  end
end
