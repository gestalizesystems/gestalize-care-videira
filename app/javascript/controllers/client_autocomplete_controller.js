import { Controller } from "@hotwired/stimulus"

// Autocomplete de cliente já cadastrado: filtra uma lista pré-carregada de
// {id, name} conforme o usuário digita e só aceita seleção via clique numa
// sugestão (o campo escondido "client_id" só é preenchido nesse momento).
// Uso:
//   <div data-controller="client-autocomplete" data-client-autocomplete-clients-value="[...]">
//     <input data-client-autocomplete-target="input" data-action="input->client-autocomplete#search focus->client-autocomplete#search">
//     <input type="hidden" name="client_id" data-client-autocomplete-target="hidden">
//     <div data-client-autocomplete-target="list"></div>
//   </div>
export default class extends Controller {
  static targets = ["input", "hidden", "list"]
  static values = { clients: Array }

  connect() {
    this.onClickOutside = (event) => {
      if (!this.element.contains(event.target)) this.hide()
    }
    document.addEventListener("click", this.onClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.onClickOutside)
  }

  search() {
    this.hiddenTarget.value = ""
    const term = this.inputTarget.value.trim().toLowerCase()
    if (term === "") return this.hide()

    const matches = this.clientsValue
      .filter((c) => c.name.toLowerCase().includes(term))
      .slice(0, 8)

    if (matches.length === 0) return this.hide()

    this.listTarget.innerHTML = matches.map((c) => {
      const name = this.escape(c.name)
      return `<button type="button" class="block w-full text-left px-4 py-2 text-sm hover:bg-[#fef8e1] cursor-pointer" data-action="click->client-autocomplete#select" data-id="${c.id}" data-name="${name}" style="color:#3E2723">${name}</button>`
    }).join("")
    this.show()
  }

  select(event) {
    this.inputTarget.value = event.currentTarget.dataset.name
    this.hiddenTarget.value = event.currentTarget.dataset.id
    this.hide()
  }

  show() { this.listTarget.classList.remove("hidden") }
  hide()  { this.listTarget.classList.add("hidden") }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
