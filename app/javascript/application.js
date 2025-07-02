// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap/dist/js/bootstrap.bundle.min.js";
window.bootstrap = bootstrap;
import "bootstrap/dist/css/bootstrap.min.css"
import { createApp } from 'vue'
import LanguageSwitcher from './components/LanguageSwitcher.vue'

import i18n from './i18n'

// Make i18n available globally
window.i18n = i18n 

// Initialize Vue app for language switcher
document.addEventListener('DOMContentLoaded', () => {
  const languageSwitcherEl = document.getElementById('language-switcher')
  if (languageSwitcherEl) {
    const app = createApp({})
    app.component('language-switcher', LanguageSwitcher)
    app.mount('#language-switcher')
  }

  // Initialize tooltips and modals
  initializeBootstrapComponents();
})

// Initialize Bootstrap components (tooltips and modals)
function initializeBootstrapComponents() {
  // Remove any existing tooltips
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
    const tooltip = bootstrap.Tooltip.getInstance(el);
    if (tooltip) tooltip.dispose();
    el.removeAttribute('data-bs-original-title');
    el.removeAttribute('aria-describedby');
    el.classList.remove('show');
    el.removeAttribute('title');
  });

  // Only add title and initialize tooltip if text is truncated
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
    const fullText = el.dataset.fulltext;
    if (!fullText) return;

    // Remove the title attribute by default
    el.removeAttribute('title');

    // Check if text is truncated
    if (el.offsetWidth < el.scrollWidth) {
      el.setAttribute('title', fullText);
      new bootstrap.Tooltip(el, {
        html: true,
        placement: el.dataset.bsPlacement || 'bottom'
      });
    }
  });

  // Initialize modals
  const modalTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="modal"]'));
  modalTriggerList.forEach(modalTriggerEl => {
    const target = modalTriggerEl.getAttribute('data-bs-target');
    if (target) {
      const modalEl = document.querySelector(target);
      if (modalEl) {
        new bootstrap.Modal(modalEl);
      }
    }
  });
}

// Reinitialize components after Turbo navigation
document.addEventListener('turbo:load', initializeBootstrapComponents);

document.addEventListener("DOMContentLoaded", function() {
  var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'))
  dropdownElementList.map(function (dropdownToggleEl) {
    new window.bootstrap.Dropdown(dropdownToggleEl)
  })
}); 