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

// Global error handler for uncaught errors
window.addEventListener('error', (event) => {
  console.error('Uncaught error:', event.error);
  if (window.quoteFormEventBus) {
    window.quoteFormEventBus.emit('set-validation-errors', [
      'Ha ocurrido un error inesperado. Por favor, intente nuevamente o contacte al soporte técnico si el problema persiste.'
    ]);
  }
});

// Global promise rejection handler
window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled promise rejection:', event.reason);
  if (window.quoteFormEventBus) {
    window.quoteFormEventBus.emit('set-validation-errors', [
      'Ha ocurrido un error inesperado. Por favor, intente nuevamente o contacte al soporte técnico si el problema persiste.'
    ]);
  }
});

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
    let preselectedProductId = null;
    
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
    preselectedProductId = el.dataset.preselectedProduct;
    
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
          // The validation is now handled inside QuoteForm.vue, so we can proceed.
          
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
          const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
          if (!csrfToken) {
            throw new Error('No se pudo obtener el token CSRF. Por favor, recargue la página e intente nuevamente.');
          }
          
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

          let data;
          try {
            data = await response.json();
          } catch (e) {
            console.error('Error parsing response:', e);
            throw new Error('Error al procesar la respuesta del servidor. Por favor, intente nuevamente.');
          }

          if (response.ok) {
            // If successful, show a success message and then redirect
            window.quoteFormEventBus.emit('quote-success', 'Cotización guardada exitosamente');
            setTimeout(() => {
              window.location.href = '/quotes';
            }, 3000); // 3-second delay
          } else {
            // Handle validation errors using event bus
            if (data.errors) {
              const errorMessages = Array.isArray(data.errors) ? 
                data.errors : 
                Object.entries(data.errors)
                  .map(([field, messages]) => `${field}: ${messages.join(', ')}`);
              window.quoteFormEventBus.emit('set-validation-errors', errorMessages);
            } else {
              const errorMessage = data.error || 
                (response.status === 422 ? 'Error de validación en los datos ingresados' :
                 response.status === 500 ? 'Error interno del servidor' :
                 'Error al guardar la cotización');
              window.quoteFormEventBus.emit('set-validation-errors', [errorMessage]);
            }
          }
        } catch (e) {
          console.error('Error in onSave handler:', e);
          // Log the full error for debugging
          console.error('Full error details:', {
            message: e.message,
            stack: e.stack,
            formData: formData
          });
          
          // Show user-friendly error message
          const errorMessage = e.message || 'Error al guardar la cotización. Por favor intente nuevamente.';
          window.quoteFormEventBus.emit('set-validation-errors', [errorMessage]);
        }
      },
      onCancel: () => {
        window.location.href = '/quotes';
      }
    });

    // Add global error handler for Vue
    app.config.errorHandler = (err, vm, info) => {
      console.error('Vue Error:', err);
      console.error('Error Info:', info);
      console.error('Component:', vm);
      
      // Show error to user
      if (window.quoteFormEventBus) {
        window.quoteFormEventBus.emit('set-validation-errors', [
          'Ha ocurrido un error en la aplicación. Por favor, recargue la página e intente nuevamente.'
        ]);
      }
      
      // Update UI to show error state
      el.innerHTML = `
        <div class="alert alert-danger my-5">
          <h4 class="alert-heading">Error en la aplicación</h4>
          <p>Ha ocurrido un error inesperado. Por favor, recargue la página e intente nuevamente.</p>
          <hr>
          <p class="mb-0">Si el problema persiste, contacte al soporte técnico.</p>
        </div>
      `;
    };

    // Store products for debug access if needed
    window.quoteFormProducts = availableProducts;

    // Mount the app
    app.mount('#quote-form-app');
    
    // Auto-add preselected product if provided
    if (preselectedProductId && window.quoteFormEventBus) {
      setTimeout(() => {
        const preselectedProduct = availableProducts.find(p => p.id == preselectedProductId);
        if (preselectedProduct) {
          // Add the product to the quote
          window.quoteFormEventBus.emit('add-product', preselectedProduct);
          
          // Set the project name to the product name
          window.quoteFormEventBus.emit('set-project-name', preselectedProduct.description || preselectedProduct.formatted_description);
        }
      }, 100); // Small delay to ensure component is fully mounted
    }
    
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