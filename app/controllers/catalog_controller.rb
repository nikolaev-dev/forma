class CatalogController < ApplicationController
  def index
    @editorial_styles = Style.editorial.ordered.limit(10)
    @popular_styles = Style.published.popular.limit(12)
    @sections = CatalogSection.active.ordered.includes(catalog_items: :item)
  end
end
