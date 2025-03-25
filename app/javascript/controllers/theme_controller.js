import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["themeInput"]

  connect() {
    this.updateTheme()
  }

  updateTheme() {
    const theme = this.themeInputTarget.value
    document.documentElement.setAttribute('data-theme', theme)
    
    // Store the theme preference in localStorage
    localStorage.setItem('theme', theme)
  }

  // Called when the radio buttons change
  toggle() {
    this.updateTheme()
  }
} 