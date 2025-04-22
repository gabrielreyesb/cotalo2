// Import dark mode theme overrides
import '../vue/vue_styles.css';

// Set Vue feature flags - required for Vue 3 esm-bundler
window.__VUE_OPTIONS_API__ = true;
window.__VUE_PROD_DEVTOOLS__ = false;
window.__VUE_PROD_HYDRATION_MISMATCH_DETAILS__ = false;

// Import Vue and our components
import { createApp } from 'vue';
import QuoteForm from '../vue/components/QuoteForm.vue';

// Create a global event bus for external communication with Vue
window.quoteFormEventBus = {
  events: {},
  
  // Register event handlers
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = [];
    }
    this.events[event].push(callback);
  },
  
  // Trigger an event
  emit(event, data) {
    if (this.events[event]) {
      this.events[event].forEach(callback => callback(data));
    }
  }
};

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  try {
    const el = document.getElementById('quote-form-app');
    if (!el) {
      console.error('Quote form app mount point not found.');
      return;
    }

    // Get data attributes from the element
    let availableProducts = [];
    let quote = {};
    let editMode = false;
    
    try {
      availableProducts = JSON.parse(el.dataset.availableProducts || '[]');
    } catch (e) {
      console.error('Error parsing availableProducts:', e);
      availableProducts = [];
    }
    
    try {
      quote = JSON.parse(el.dataset.quote || '{}');
    } catch (e) {
      console.error('Error parsing quote:', e);
      quote = {};
    }
    
    editMode = el.dataset.editMode === 'true';

    // Create and mount the Vue app with the component directly
    const app = createApp(QuoteForm, {
      availableProducts,
      quote,
      editMode,
      onSave: (formData) => {
        try {
          // Create a data object with the form data and selected products
          const quoteData = {
            ...formData.form,
            selected_products: formData.selectedProducts.map(p => ({
              product_id: p.id,
              quantity: p.quantity
            })),
            data: {
              totals: {
                subtotal: formData.totals.subtotal,
                tax_percentage: formData.totals.taxPercentage,
                tax: formData.totals.tax,
                total: formData.totals.total
              }
            }
          };

          // Create a hidden form to submit the data to Rails
          const form = document.createElement('form');
          form.method = 'post';
          form.action = editMode ? `/quotes/${quote.id}` : '/quotes';
          form.style.display = 'none';

          // Add CSRF token
          const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
          
          const csrfInput = document.createElement('input');
          csrfInput.type = 'hidden';
          csrfInput.name = 'authenticity_token';
          csrfInput.value = csrfToken;
          form.appendChild(csrfInput);

          // Add method override for PUT/PATCH if editing
          if (editMode) {
            const methodInput = document.createElement('input');
            methodInput.type = 'hidden';
            methodInput.name = '_method';
            methodInput.value = 'patch';
            form.appendChild(methodInput);
          }

          // Add the quote data as a hidden field
          const quoteInput = document.createElement('input');
          quoteInput.type = 'hidden';
          quoteInput.name = 'quote_data';
          quoteInput.value = JSON.stringify(quoteData);
          form.appendChild(quoteInput);

          // Append the form to the body and submit it
          document.body.appendChild(form);
          form.submit();
        } catch (e) {
          console.error('Error in onSave handler:', e);
        }
      },
      onCancel: () => {
        window.location.href = '/quotes';
      }
    });

    // Add global error handler
    app.config.errorHandler = (err, vm, info) => {
      console.error('Vue Error:', err);
      console.error('Error Info:', info);
      el.innerHTML = `
        <div class="alert alert-danger my-5">
          <h4 class="alert-heading">Vue Application Error</h4>
          <p>${err.message}</p>
          <hr>
          <p class="mb-0">Please check the console for more details.</p>
        </div>
      `;
    };

    // Store products for debug access if needed
    window.quoteFormProducts = availableProducts;

    // Mount the app
    app.mount('#quote-form-app');
    
    // Simple external product add helper
    window.debugAddProduct = function(productId) {
      try {
        const product = window.quoteFormProducts.find(p => p.id === productId);
        if (product && window.quoteFormEventBus) {
          window.quoteFormEventBus.emit('add-product', product);
          return true;
        }
      } catch (e) {
        console.error('Error adding product:', e);
      }
      return false;
    };
    
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