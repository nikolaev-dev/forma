import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "dot", "label", "spinner", "message", "error"]
  static values = {
    url: String,
    resultUrl: String,
    interval: { type: Number, default: 2000 }
  }

  connect() {
    this.poll()
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue)
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this.updateProgress(data.progress_step)

      if (data.is_terminal) {
        if (data.status === "succeeded" || data.status === "partial") {
          window.Turbo.visit(this.resultUrlValue)
        } else {
          this.showError()
        }
        return
      }
    } catch (e) {
      // Network error — continue polling
    }

    this.timer = setTimeout(() => this.poll(), this.intervalValue)
  }

  updateProgress(step) {
    this.dotTargets.forEach((dot, i) => {
      const s = i + 1
      if (s <= step) {
        dot.classList.remove("border-forma-gray-300", "text-forma-gray-400")
        dot.classList.add("border-forma-black", "bg-forma-black", "text-white")
      }
    })

    this.labelTargets.forEach((label, i) => {
      const s = i + 1
      if (s <= step) {
        label.classList.remove("text-forma-gray-400")
        label.classList.add("text-forma-black", "font-medium")
      }
    })

    const messages = {
      1: "Подготавливаем промпт...",
      2: "Генерируем изображения...",
      3: "Почти готово..."
    }
    this.messageTarget.textContent = messages[step] || "Создаём ваш дизайн..."
  }

  showError() {
    this.spinnerTarget.classList.add("hidden")
    this.messageTarget.classList.add("hidden")
    this.errorTarget.classList.remove("hidden")
  }
}
