module DesignsHelper
  def design_og_description(design)
    parts = []
    parts << design.tags.where(visibility: "public").pluck(:name).join(", ") if design.tags.any?
    parts << "Создай свой на FORMA"
    parts.join(" — ")
  end
end
