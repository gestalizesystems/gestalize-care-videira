import { Controller } from "@hotwired/stimulus"

// Abre o seletor nativo (arquivo / galeria / câmera) ao clicar no ícone e
// mostra a pré-visualização da foto escolhida antes de salvar.
export default class extends Controller {
  static targets = ["input", "current"]

  // Câmera: força a abertura da câmera (e pedido de acesso) no celular.
  openCamera() { this.pick("environment") }
  // Galeria / Arquivos: abrem o seletor de imagens do sistema.
  openGallery() { this.pick(null) }
  openFiles()   { this.pick(null) }

  pick(capture) {
    if (capture) this.inputTarget.setAttribute("capture", capture)
    else         this.inputTarget.removeAttribute("capture")
    this.inputTarget.setAttribute("accept", "image/*")

    const dialog = document.getElementById("avatar-source-modal")
    if (dialog && dialog.open) dialog.close()

    this.inputTarget.click()
  }

  preview() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file) return
    const url = URL.createObjectURL(file)
    this.currentTarget.innerHTML =
      `<img src="${url}" alt="Pré-visualização" class="w-24 h-24 rounded-full object-cover">`
  }
}
