import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prompt", "submit"]

  connect() {
    this.validate()
  }

  validate() {
    const hasPrompt = this.promptTarget.value.trim().length > 0
    this.submitTarget.disabled = !hasPrompt
  }
}
