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
    let translations = {};
    
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
    
    try {
      translations = JSON.parse(el.dataset.translations || '{}');
    } catch (e) {
      console.error('Error parsing translations:', e);
      translations = {};
    }

    // Create and mount the Vue app with the component directly
    const app = createApp(QuoteForm, {
      availableProducts,
      quote,
      editMode,
      translations,
      onSave: async (formData) => {
        try {
          // Clear previous errors
          if (app._instance && app._instance.proxy && app._instance.proxy.clearValidationErrors) {
            app._instance.proxy.clearValidationErrors();
          }
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

          // Get CSRF token
          const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
          
          // Submit the form data via fetch
          const response = await fetch(editMode ? `/quotes/${quote.id}.json` : '/quotes.json', {
            method: editMode ? 'PATCH' : 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': csrfToken,
              'Accept': 'application/json'
            },
            body: JSON.stringify({ quote_data: quoteData })
          });

          const data = await response.json();

          if (response.ok) {
            // If successful, redirect to quotes index
            window.location.href = '/quotes';
          } else {
            // Handle validation errors
            if (data.errors) {
              if (Array.isArray(data.errors)) {
                app._instance.proxy.setValidationErrors(data.errors);
              } else {
                const errorMessages = Object.entries(data.errors)
                  .map(([field, messages]) => `${field}: ${messages.join(', ')}`);
                app._instance.proxy.setValidationErrors(errorMessages);
              }
            } else {
              app._instance.proxy.setValidationErrors([data.error || 'Error al guardar la cotización']);
            }
          }
        } catch (e) {
          console.error('Error in onSave handler:', e);
          if (app._instance && app._instance.proxy && app._instance.proxy.setValidationErrors) {
            app._instance.proxy.setValidationErrors(['Error al guardar la cotización. Por favor intente nuevamente.']);
          }
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