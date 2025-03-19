// Import Bootstrap only once
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';

// Import Chart.js
import 'chart.js/auto';

// Import dark mode theme overrides
import '../vue/vue_styles.css';

// Set Vue feature flags - required for Vue 3 esm-bundler
window.__VUE_OPTIONS_API__ = true;
window.__VUE_PROD_DEVTOOLS__ = false;
window.__VUE_PROD_HYDRATION_MISMATCH_DETAILS__ = false;

// Import Vue and our components
import { createApp } from 'vue';
import ProductForm from '../vue/components/product/ProductForm.vue';

console.log('Product form JS loaded');

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, initializing Vue app');
  
  try {
    const appElement = document.getElementById('product-form-app');
    
    if (appElement) {
      // Get product ID from data attribute (can be null for new products)
      const productId = appElement.dataset.productId || null;
      const isNew = !productId || productId === '';
      
      console.log('App mount element found with data attributes:', { 
        productId: productId, 
        isNew: isNew
      });
      
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
      console.log('Vue app mounted with productId:', productId, 'isNew:', isNew);
    } else {
      console.error('Product form app element not found');
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