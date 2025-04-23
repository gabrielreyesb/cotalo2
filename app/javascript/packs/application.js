/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import * as bootstrap from 'bootstrap'
import '@popperjs/core'

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
  import("../controllers").catch(e => {
    console.log("Stimulus not loaded, continuing without it");
  });
} catch (e) {
  console.log("Stimulus not available, continuing without it");
}

// Initialize Webpacker
