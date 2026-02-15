import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  static values = { dismissAfter: { type: Number, default: 4000 } }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.remove()
  }
}
