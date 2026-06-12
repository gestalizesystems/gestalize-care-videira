import { Controller } from "@hotwired/stimulus"

const MONTHS = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
const WDAYS  = ["DOM","SEG","TER","QUA","QUI","SEX","SÁB"]

export default class extends Controller {
  static targets = ["dialog", "grid", "label"]
  static values  = { selected: String, min: String, max: String, base: String }

  connect() {
    const d = new Date(this.selectedValue + "T12:00:00")
    this.year  = d.getFullYear()
    this.month = d.getMonth()
    this.render()
  }

  open(event) {
    event.preventDefault()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }

  prev() {
    if (this.month === 0) { this.month = 11; this.year-- } else { this.month-- }
    this.render()
  }

  next() {
    if (this.month === 11) { this.month = 0; this.year++ } else { this.month++ }
    this.render()
  }

  pick(event) {
    const date = event.currentTarget.dataset.date
    this.dialogTarget.close()
    window.location.href = (this.baseValue || "/") + "?date=" + date
  }

  pad(n) { return String(n).padStart(2, "0") }

  render() {
    this.labelTarget.textContent = `${MONTHS[this.month]} de ${this.year}`

    const min  = new Date(this.minValue  + "T12:00:00")
    const max  = new Date(this.maxValue  + "T12:00:00")
    const sel  = this.selectedValue

    const firstWday = new Date(this.year, this.month, 1).getDay()
    const lastDay   = new Date(this.year, this.month + 1, 0).getDate()

    let html = `<div class="grid grid-cols-7 gap-0.5 mb-2">`
    WDAYS.forEach(d => {
      html += `<div class="text-center text-xs font-medium py-1" style="color:#8D6E63">${d}</div>`
    })
    html += `</div><div class="grid grid-cols-7 gap-0.5">`

    for (let i = 0; i < firstWday; i++) html += `<div></div>`

    const today    = new Date()
    const todayStr = `${today.getFullYear()}-${this.pad(today.getMonth() + 1)}-${this.pad(today.getDate())}`

    for (let day = 1; day <= lastDay; day++) {
      const dateStr = `${this.year}-${this.pad(this.month + 1)}-${this.pad(day)}`
      const date    = new Date(dateStr + "T12:00:00")
      const isSel   = dateStr === sel
      const isOff   = date < min || date > max
      const isToday = dateStr === todayStr
      const ring    = isToday ? "border:1.5px solid #5D4037;" : ""

      if (isSel) {
        html += `<div class="flex items-center justify-center h-8 w-8 mx-auto rounded-full text-xs font-bold text-white" style="background-color:#5D4037;${ring}">${day}</div>`
      } else if (isToday) {
        if (isOff) {
          html += `<div class="flex items-center justify-center h-8 w-8 mx-auto rounded-full text-xs font-bold" style="color:#5D4037;${ring}">${day}</div>`
        } else {
          html += `<button data-action="click->calendar#pick" data-date="${dateStr}"
                           class="flex items-center justify-center h-8 w-8 mx-auto rounded-full text-xs font-bold transition-colors hover:bg-[#fef8e1]"
                           style="color:#5D4037;${ring}">${day}</button>`
        }
      } else if (isOff) {
        html += `<div class="flex items-center justify-center h-8 w-8 mx-auto text-xs opacity-25" style="color:#5D4037">${day}</div>`
      } else {
        html += `<button data-action="click->calendar#pick" data-date="${dateStr}"
                         class="flex items-center justify-center h-8 w-8 mx-auto rounded-full text-xs font-medium transition-colors hover:bg-[#fef8e1]"
                         style="color:#5D4037">${day}</button>`
      }
    }
    html += `</div>`
    this.gridTarget.innerHTML = html
  }
}
