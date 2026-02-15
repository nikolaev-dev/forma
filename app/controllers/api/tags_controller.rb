module Api
  class TagsController < BaseController
    def search
      query = params[:q].to_s.strip
      if query.blank?
        return render json: { error: "query required" }, status: :bad_request
      end

      tags = Tag.available.search_by_name(query).limit(10)

      render json: {
        tags: tags.map { |t| { id: t.id, name: t.name, slug: t.slug, category: t.tag_category.name } }
      }
    end
  end
end
