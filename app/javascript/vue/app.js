import { createApp } from 'vue'
import ProductForm from './components/Product.vue'
import SimpleModal from './components/SimpleModal.vue'

// Create and mount the root instance
document.addEventListener('DOMContentLoaded', () => {
  const productEl = document.getElementById('product-app')
  const modalTestEl = document.getElementById('app')
  
  if (productEl) {
    // Get data from the element's data attributes
    const materials = JSON.parse(productEl.dataset.materials || '[]')
    const product = JSON.parse(productEl.dataset.product || '{}')
    const editMode = JSON.parse(productEl.dataset.editMode || 'false')
    
    // Create the app
    const app = createApp({
      components: {
        ProductForm
      },
      data() {
        return {
          materials,
          product,
          editMode
        }
      },
      methods: {
        handleSave(formData) {
          // Create a hidden form to submit the data to Rails
          const form = document.createElement('form')
          form.method = 'POST'
          form.action = editMode ? `/products/${product.id}` : '/products'
          
          // Add CSRF token
          const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          const csrfField = document.createElement('input')
          csrfField.type = 'hidden'
          csrfField.name = 'authenticity_token'
          csrfField.value = csrfToken
          form.appendChild(csrfField)
          
          // Add HTTP method override if editing
          if (editMode) {
            const methodField = document.createElement('input')
            methodField.type = 'hidden'
            methodField.name = '_method'
            methodField.value = 'PATCH'
            form.appendChild(methodField)
          }
          
          // Create a hidden field for the product data
          const productField = document.createElement('input')
          productField.type = 'hidden'
          productField.name = 'product'
          productField.value = JSON.stringify(formData)
          form.appendChild(productField)
          
          // Submit the form
          document.body.appendChild(form)
          form.submit()
        },
        handleCancel() {
          window.location.href = '/products'
        }
      },
      template: `
        <ProductForm 
          :materials="materials" 
          :product="product" 
          :editMode="editMode"
          @save="handleSave" 
          @cancel="handleCancel" 
        />
      `
    })
    
    // Mount the app
    app.mount('#product-app')
  }

  if (modalTestEl) {
    const app = createApp({
      components: {
        SimpleModal
      },
      template: '<SimpleModal />'
    })
    
    app.mount('#app')
  }
}) 