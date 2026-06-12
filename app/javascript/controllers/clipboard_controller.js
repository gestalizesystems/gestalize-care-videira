import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "success"]

  copy() {
    const text = this.sourceTarget.value
    navigator.clipboard.writeText(text).then(() => {
      if (this.hasSuccessTarget) {
        this.successTarget.classList.remove("hidden")
        setTimeout(() => this.successTarget.classList.add("hidden"), 2000)
      }
    }).catch(() => {
      // fallback para browsers antigos
      this.sourceTarget.select()
      document.execCommand("copy")
    })
  }
}
