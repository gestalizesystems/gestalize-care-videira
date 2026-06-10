import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "results", "empty", "data", "confirmText", "availabilityId", "dentistId"]

  connect() {
    try { this.items = JSON.parse(this.dataTarget.textContent || "[]") }
    catch { this.items = [] }
  }

  // Abre o modal de busca de cliente para o turno clicado.
  open({ params: { id, date, label, time } }) {
    this.av = { id, date, label, time }
    this.availabilityIdTarget.value = id
    this.searchTarget.value = ""
    this.render(this.items)
    document.getElementById("book-slot-modal").showModal()
    setTimeout(() => this.searchTarget.focus(), 50)
  }

  filter() {
    const q = this.searchTarget.value.trim().toLowerCase()
    const matches = q === "" ? this.items : this.items.filter(i => i.name.toLowerCase().includes(q))
    this.render(matches)
  }

  render(list) {
    if (list.length === 0) {
      this.resultsTarget.innerHTML = ""
      this.emptyTarget.classList.remove("hidden")
      return
    }
    this.emptyTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = list.map(i => `
      <li>
        <button type="button" data-action="click->book-slot#pick"
                data-id="${i.id}" data-name="${this.escape(i.name)}"
                class="w-full flex items-center justify-between gap-2 px-4 py-3 rounded-2xl bg-[#FBF6E4] hover:bg-[#fef8e1] cursor-pointer transition-colors">
          <span class="text-sm font-medium truncate" style="color:#3E2723">${this.escape(i.name)}</span>
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24"
               stroke="currentColor" stroke-width="2" style="color:#8D6E63">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
          </svg>
        </button>
      </li>`).join("")
  }

  // Seleciona o cliente e abre o modal de confirmação.
  pick(event) {
    const { id, name } = event.currentTarget.dataset
    this.dentistIdTarget.value = id
    this.confirmTextTarget.textContent =
      `Deseja adicionar ${this.av.date} - ${this.av.label} ${this.av.time} para ${name}?`
    document.getElementById("book-slot-modal").close()
    document.getElementById("confirm-booking-modal").showModal()
  }

  escape(s) {
    return String(s).replace(/[&<>"']/g, c => (
      { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
    ))
  }
}
