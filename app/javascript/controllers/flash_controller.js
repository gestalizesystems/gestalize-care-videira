import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 3000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
  }

  disconnect() { clearTimeout(this.timer) }

  dismiss() {
    this.element.style.transition = "opacity 200ms"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 200)
  }
}
