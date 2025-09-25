import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('shown.bs.modal', this.focusInput.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('shown.bs.modal', this.focusInput.bind(this))
  }

  focusInput() {
    const input = this.element.querySelector('input[type="email"]')
    if (input) {
      input.focus()
      // Asegurarnos que el cursor se posicione al final del texto si hay alguno
      const value = input.value
      input.value = ''
      input.value = value
    }
  }
}
