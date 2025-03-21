// Import Bootstrap
import 'bootstrap/dist/js/bootstrap.bundle.min.js';

// Import dark mode theme overrides
import '../vue/vue_styles.css';

// Debug message to confirm the script is loaded
console.log('quote_form.js loaded successfully');

// Set Vue feature flags - required for Vue 3 esm-bundler
window.__VUE_OPTIONS_API__ = true;
window.__VUE_PROD_DEVTOOLS__ = false;
window.__VUE_PROD_HYDRATION_MISMATCH_DETAILS__ = false;

// Import Vue and our components
import { createApp } from 'vue';
import QuoteForm from '../vue/components/QuoteForm.vue';

// Add global error handler
window.addEventListener('error', function(event) {
  console.error('Global error caught:', event.error);
});

// Add unhandled promise rejection handler
window.addEventListener('unhandledrejection', function(event) {
  console.error('Unhandled promise rejection:', event.reason);
});

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  try {
    const el = document.getElementById('quote-form-app');
    if (!el) {
      console.error('Quote form app mount point not found.');
      return;
    }

    console.log('Quote form app mount point found:', el);

    // Get data attributes from the element
    let availableProducts = [];
    let quote = {};
    let editMode = false;
    
    try {
      availableProducts = JSON.parse(el.dataset.availableProducts || '[]');
      console.log('Available products parsed successfully. Count:', availableProducts.length);
      if (availableProducts.length > 0) {
        console.log('First product:', availableProducts[0]);
      }
    } catch (e) {
      console.error('Error parsing availableProducts:', e);
      availableProducts = [];
    }
    
    try {
      quote = JSON.parse(el.dataset.quote || '{}');
      console.log('Quote parsed successfully:', Object.keys(quote));
    } catch (e) {
      console.error('Error parsing quote:', e);
      quote = {};
    }
    
    editMode = el.dataset.editMode === 'true';
    console.log('Edit mode:', editMode);

    // Create and mount the Vue app with the component directly
    const app = createApp(QuoteForm, {
      availableProducts,
      quote,
      editMode,
      onSave: (formData) => {
        try {
          console.log('Saving form data:', formData);
          
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

          console.log('Quote data prepared for submission:', quoteData);

          // Create a hidden form to submit the data to Rails
          const form = document.createElement('form');
          form.method = 'post';
          form.action = editMode ? `/quotes/${quote.id}` : '/quotes';
          form.style.display = 'none';

          // Add CSRF token
          const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
          if (!csrfToken) {
            console.error('CSRF token not found!');
          } else {
            console.log('CSRF token found');
          }
          
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
          console.log('Form created and ready to submit');
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

    // Mount the app
    console.log('Mounting Vue app...');
    app.mount('#quote-form-app');
    console.log('Vue app mounted successfully');
    
    // For debugging: add a direct click handler to ensure Vue is responding
    window.debugAddProduct = function(productId) {
      try {
        console.log(`Debug: Adding product ${productId}...`);
        const product = availableProducts.find(p => p.id === productId);
        if (product) {
          console.log('Debug: Product found:', product);
          // Try to find the Vue instance
          const quoteFormInstance = app._instance.proxy;
          if (quoteFormInstance && typeof quoteFormInstance.addProduct === 'function') {
            console.log('Debug: Vue instance found, calling addProduct()');
            quoteFormInstance.addProduct(product);
            return true;
          } else {
            console.error('Debug: Vue instance or addProduct method not found');
          }
        } else {
          console.error(`Debug: Product ${productId} not found in availableProducts`);
        }
      } catch (e) {
        console.error('Debug: Error in debugAddProduct:', e);
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