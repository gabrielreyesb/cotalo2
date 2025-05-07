// Import Chart.js
import 'chart.js/auto';

// Set Vue feature flags - required for Vue 3 esm-bundler
window.__VUE_OPTIONS_API__ = true;
window.__VUE_PROD_DEVTOOLS__ = false;
window.__VUE_PROD_HYDRATION_MISMATCH_DETAILS__ = false;

// Import Vue and our components
import { createApp } from 'vue';
import ProductForm from '../vue/components/product/ProductForm.vue';

// Global error handler for unexpected errors
window.addEventListener('error', function(event) {
  console.error('Global error caught:', event.error);
  document.body.innerHTML += `
    <div class="alert alert-danger my-5 container">
      <h4 class="alert-heading">JavaScript Error</h4>
      <p>${event.error?.message || 'Unknown error'}</p>
      <hr>
      <p class="mb-0">Please check the browser console for more details.</p>
    </div>
  `;
});

// Safely get stylesheet information
function getStylesheetInfo(sheet) {
  try {
    return {
      href: sheet.href || 'inline',
      // Only try to access rules for same-origin stylesheets
      rules: sheet.href && new URL(sheet.href).origin !== window.location.origin ? 
        'cross-origin' : 
        (sheet.cssRules ? sheet.cssRules.length : 'no rules')
    };
  } catch (e) {
    return {
      href: sheet.href || 'inline',
      rules: 'inaccessible'
    };
  }
}


// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  
  try {
    const appElement = document.getElementById('product-form-app');
    
    if (appElement) {
      // Get product ID from data attribute (can be null for new products)
      const productId = appElement.dataset.productId || null;
      const isNew = !productId || productId === '';
      
      // Create and mount the Vue app
      const app = createApp(ProductForm, {
        productId: productId,
        isNew: isNew
      });
      
      // Add global error handler
      app.config.errorHandler = (err, vm, info) => {
        console.error('Vue Error:', err);
        console.error('Error Info:', info);
        document.getElementById('product-form-app').innerHTML = `
          <div class="alert alert-danger my-5">
            <h4 class="alert-heading">Vue Application Error</h4>
            <p>${err.message}</p>
            <hr>
            <p class="mb-0">Please check the console for more details.</p>
          </div>
        `;
      };
      
      app.mount(appElement);
    } else {
      document.body.innerHTML += `
        <div class="alert alert-danger my-5 container">
          <h4 class="alert-heading">Initialization Error</h4>
          <p>The product form mount element was not found.</p>
          <hr>
          <p class="mb-0">Please check if the page has the correct HTML structure.</p>
        </div>
      `;
    }
  } catch (error) {
    console.error('Error initializing Vue app:', error);
    document.body.innerHTML += `
      <div class="alert alert-danger my-5 container">
        <h4 class="alert-heading">Critical Error</h4>
        <p>${error.message}</p>
        <hr>
        <p class="mb-0">Please contact support with these error details.</p>
      </div>
    `;
  }
}); 