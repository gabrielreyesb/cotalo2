// Import Bootstrap only once
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';

// Import dark mode theme overrides
import '../vue/vue_styles.css';

// Import Vue and our components
import { createApp } from 'vue';
import ProductForm from '../vue/components/product/ProductForm.vue';

console.log('Product form JS loaded');

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, initializing Vue app');
  
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
    
    app.mount(appElement);
    console.log('Vue app mounted with productId:', productId, 'isNew:', isNew);
  } else {
    console.error('Product form app element not found');
  }
}); 