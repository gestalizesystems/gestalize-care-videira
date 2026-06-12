import { Controller } from "@hotwired/stimulus"

// Atualiza ao vivo "crédito usado" e "a pagar" conforme o cliente escolhe
// quanto crédito aplicar no checkout. Crédito é opcional (pode usar 0).
export default class extends Controller {
  static targets = ["input", "usedField", "usedRow", "usedAmount", "due", "pix", "submit"]
  static values  = { total: Number, balance: Number }

  connect() {
    if (this.hasInputTarget) this.recompute()
  }

  recompute() {
    const total   = this.totalValue
    const balance = this.balanceValue
    const raw     = this.inputTarget.value.trim()

    let requested = raw === "" ? Math.min(balance, total) : Math.round(parseFloat(raw.replace(",", ".")) * 100)
    if (isNaN(requested) || requested < 0) requested = 0

    const used = Math.min(requested, balance, total)
    const due  = total - used

    if (this.hasUsedFieldTarget)  this.usedFieldTarget.textContent  = this.fmt(used)
    if (this.hasUsedAmountTarget) this.usedAmountTarget.textContent = this.fmt(used)
    if (this.hasDueTarget)        this.dueTarget.textContent        = this.fmt(due)
    if (this.hasUsedRowTarget)    this.usedRowTarget.style.display  = used > 0 ? "" : "none"
    if (this.hasPixTarget)        this.pixTarget.style.display      = due > 0 ? "" : "none"
    if (this.hasSubmitTarget)     this.submitTarget.value           = due === 0 ? "Confirmar reserva" : "Pagar"
  }

  fmt(cents) {
    return "R$ " + (cents / 100).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
