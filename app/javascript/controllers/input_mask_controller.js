import { Controller } from "@hotwired/stimulus"

// Aplica máscara de formatação em inputs de telefone e CPF.
// Uso:
//   <input data-controller="input-mask" data-input-mask-pattern-value="phone">
//   <input data-controller="input-mask" data-input-mask-pattern-value="cpf">
//
// O valor exibido fica formatado; no submit, os dígitos crus são enviados ao servidor
// (compatível com a validação `\A\d{11}\z` do model).
export default class extends Controller {
  static values = { pattern: String }

  connect() {
    this.format()
    this.element.addEventListener("input", this.onInput)
    this.element.form?.addEventListener("formdata", this.onFormData)
  }

  disconnect() {
    this.element.removeEventListener("input", this.onInput)
    this.element.form?.removeEventListener("formdata", this.onFormData)
  }

  onInput = () => this.format()

  onFormData = (event) => {
    const name = this.element.name
    if (!name) return
    event.formData.set(name, this.submitValue())
  }

  submitValue() {
    if (this.patternValue === "money") {
      const d = this.digits()
      return d === "" ? "" : (parseInt(d, 10) / 100).toFixed(2)
    }
    // CRO mantém o valor formatado (contém UF + número).
    if (this.patternValue === "cro") return this.element.value
    return this.digits()
  }

  format() {
    if (this.patternValue === "cpf")   { this.element.value = this.formatCpf(this.digits());   return }
    if (this.patternValue === "money") { this.element.value = this.formatMoney(this.digits()); return }
    if (this.patternValue === "cro")   { this.element.value = this.formatCro(this.element.value); return }
    this.element.value = this.formatPhone(this.digits())
  }

  // Formato: CRO-XX 00000  (XX = UF, depois o número de inscrição)
  formatCro(raw) {
    let v = (raw || "").toUpperCase().replace(/[^A-Z0-9]/g, "").replace(/^CRO/, "")
    const letters = v.replace(/[0-9]/g, "").slice(0, 2)
    const digits  = v.replace(/[A-Z]/g, "").slice(0, 6)
    if (letters === "" && digits === "") return ""
    let out = "CRO-" + letters
    if (digits) out += (letters.length === 2 ? " " : "") + digits
    return out
  }

  formatMoney(d) {
    d = d.replace(/^0+/, "")
    if (d === "") return ""
    while (d.length < 3) d = "0" + d
    const cents = d.slice(-2)
    const intPart = d.slice(0, -2).replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    return `R$ ${intPart},${cents}`
  }

  digits() {
    return (this.element.value || "").replace(/\D/g, "")
  }

  formatCpf(d) {
    d = d.slice(0, 11)
    if (d.length <= 3)  return d
    if (d.length <= 6)  return `${d.slice(0,3)}.${d.slice(3)}`
    if (d.length <= 9)  return `${d.slice(0,3)}.${d.slice(3,6)}.${d.slice(6)}`
    return `${d.slice(0,3)}.${d.slice(3,6)}.${d.slice(6,9)}-${d.slice(9)}`
  }

  formatPhone(d) {
    d = d.slice(0, 11)
    if (d.length === 0)  return ""
    if (d.length <= 2)   return `(${d}`
    if (d.length <= 6)   return `(${d.slice(0,2)}) ${d.slice(2)}`
    if (d.length <= 10)  return `(${d.slice(0,2)}) ${d.slice(2,6)}-${d.slice(6)}`
    return `(${d.slice(0,2)}) ${d.slice(2,7)}-${d.slice(7)}`
  }
}
