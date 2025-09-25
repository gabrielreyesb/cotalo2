import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('shown.bs.modal', this.focusEmailField.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('shown.bs.modal', this.focusEmailField.bind(this))
  }

  focusEmailField() {
    const emailField = this.element.querySelector('input[type="email"]')
    if (emailField) {
      emailField.focus()
    }
  }
}
