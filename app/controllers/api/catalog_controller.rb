module Api
  class CatalogController < BaseController
    # GET /api/catalog/styles
    def styles
      styles = Style.published.ordered.includes(:tags)
      render_json(styles.map { |s| style_json(s) })
    end

    # GET /api/catalog/sections
    def sections
      sections = CatalogSection.active.ordered.includes(catalog_items: :item)
      render_json(sections.map { |s| section_json(s) })
    end

    private

    def style_json(style)
      {
        id: style.hashid,
        name: style.name,
        slug: style.slug,
        description: style.description,
        tags: style.tags.map { |t| { name: t.name, slug: t.slug } }
      }
    end

    def section_json(section)
      {
        name: section.name,
        slug: section.slug,
        section_type: section.section_type,
        items: section.catalog_items.ordered.map { |ci| catalog_item_json(ci) }
      }
    end

    def catalog_item_json(catalog_item)
      item = catalog_item.item
      {
        type: catalog_item.item_type,
        id: item.respond_to?(:hashid) ? item.hashid : item.id,
        name: item.name,
        slug: item.respond_to?(:slug) ? item.slug : nil,
        pinned: catalog_item.pinned
      }
    end
  end
end
