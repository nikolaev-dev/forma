module AdminHelper
  def admin_nav_link(label, path, section)
    active = request.path.start_with?(path) || (section == "dashboard" && request.path == admin_root_path)
    css = active ? "bg-gray-100 text-gray-900 font-medium" : "text-gray-600 hover:bg-gray-50"

    content_tag(:li) do
      link_to label, path, class: "block px-3 py-2 rounded-md #{css}"
    end
  end
end
