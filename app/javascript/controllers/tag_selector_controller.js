import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["inputs"]

  selectedIds = new Set()

  toggle(event) {
    const button = event.currentTarget
    const tagId = button.dataset.tagSelectorTagIdParam

    if (this.selectedIds.has(tagId)) {
      this.selectedIds.delete(tagId)
      button.classList.remove("bg-forma-black", "text-white", "border-forma-black")
      button.classList.add("bg-white", "text-forma-gray-700", "border-forma-gray-200")
    } else {
      this.selectedIds.add(tagId)
      button.classList.remove("bg-white", "text-forma-gray-700", "border-forma-gray-200")
      button.classList.add("bg-forma-black", "text-white", "border-forma-black")
    }

    this.updateInputs()
  }

  updateInputs() {
    this.inputsTarget.innerHTML = ""
    this.selectedIds.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "creation[tag_ids][]"
      input.value = id
      this.inputsTarget.appendChild(input)
    })
  }
}
