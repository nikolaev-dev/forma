import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["carousel", "card", "dot"]

  connect() {
    if (!this.hasCarouselTarget || !this.hasDotTarget) return

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const index = parseInt(entry.target.dataset.index, 10)
            this.activateDot(index)
          }
        })
      },
      { root: this.carouselTarget, threshold: 0.5 }
    )

    this.cardTargets.forEach(card => this.observer.observe(card))
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  activateDot(index) {
    this.dotTargets.forEach((dot, i) => {
      if (i === index) {
        dot.classList.remove("bg-forma-gray-300")
        dot.classList.add("bg-forma-black")
      } else {
        dot.classList.remove("bg-forma-black")
        dot.classList.add("bg-forma-gray-300")
      }
    })
  }
}
