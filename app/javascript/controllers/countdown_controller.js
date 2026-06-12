import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values  = { expiresAt: String }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const expires = new Date(this.expiresAtValue)
    const now     = new Date()
    const diff    = Math.max(0, Math.floor((expires - now) / 1000))

    if (diff === 0) {
      clearInterval(this.timer)
      if (this.hasDisplayTarget) this.displayTarget.textContent = "00:00"
      return
    }

    const minutes = String(Math.floor(diff / 60)).padStart(2, "0")
    const seconds = String(diff % 60).padStart(2, "0")
    if (this.hasDisplayTarget) this.displayTarget.textContent = `${minutes}:${seconds}`
  }
}
