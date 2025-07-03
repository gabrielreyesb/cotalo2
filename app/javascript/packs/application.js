/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import * as bootstrap from 'bootstrap'
import '@popperjs/core'
import 'sweetalert2/src/sweetalert2.scss'
import Swal from 'sweetalert2'
import 'vue-multiselect/dist/vue-multiselect.min.css'

window.bootstrap = bootstrap

// Global notification utilities
const Toast = Swal.mixin({
  toast: true,
  position: 'top-end',
  showConfirmButton: false,
  timer: 5000,
  timerProgressBar: true,
  didOpen: (toast) => {
    toast.addEventListener('mouseenter', Swal.stopTimer);
    toast.addEventListener('mouseleave', Swal.resumeTimer);
  }
});

window.showSuccess = (message) => {
  Toast.fire({
    icon: 'success',
    title: message
  });
};

window.showError = (message) => {
  Toast.fire({
    icon: 'error',
    title: message
  });
};

window.showWarning = (message) => {
  Toast.fire({
    icon: 'warning',
    title: message
  });
};

window.showInfo = (message) => {
  Toast.fire({
    icon: 'info',
    title: message
  });
};

// Initialize all Bootstrap dropdowns
document.addEventListener('DOMContentLoaded', function() {
  // Initialize all dropdowns
  var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'))
  var dropdownList = dropdownElementList.map(function (dropdownToggleEl) {
    return new bootstrap.Dropdown(dropdownToggleEl)
  })
  
  // Remove debug elements in production
  document.querySelectorAll('*').forEach(function(node) {
    if (node.textContent === 'EMPTY') {
      node.parentNode.style.display = 'none';
    }
  });
  
  // Remove elements with red borders
  document.querySelectorAll('[style*="border: 3px solid red"], [style*="border:3px solid red"]').forEach(function(node) {
    node.style.display = 'none';
  });
});

// Only try to import Stimulus controllers if actually being used in the page
try {
  // Import Stimulus controllers conditionally
  import("../controllers")
} catch (e) {
  // Stimulus not available, continuing without it
}
