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

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', () => {
  try {
    const el = document.getElementById('quote-form-app');
    if (!el) return;

    // Get data attributes from the element
    const availableProducts = JSON.parse(el.dataset.availableProducts || '[]');
    const quote = JSON.parse(el.dataset.quote || '{}');
    const editMode = el.dataset.editMode === 'true';

    // Create and mount the Vue app with the component directly
    const app = createApp(QuoteForm, {
      availableProducts,
      quote,
      editMode,
      onSave: (formData) => {
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
    app.mount('#quote-form-app');
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