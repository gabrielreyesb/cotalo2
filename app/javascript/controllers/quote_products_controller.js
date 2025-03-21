import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["productSearch", "productList", "notification"]
  
  connect() {
    this.setupEventListeners()
  }
  
  setupEventListeners() {
    // Auto-submit quantity forms when input changes
    document.querySelectorAll('.product-quantity-form').forEach(form => {
      const input = form.querySelector('input[type="number"]')
      if (input) {
        input.addEventListener('change', () => {
          form.requestSubmit()
        })
      }
    })
  }
  
  filterProducts() {
    const query = this.productSearchTarget.value.toLowerCase()
    const rows = this.productListTarget.querySelectorAll('tr')
    
    rows.forEach(row => {
      const productName = row.querySelector('td:first-child')
      if (productName) {
        const text = productName.textContent.toLowerCase()
        if (text.includes(query)) {
          row.style.display = ''
        } else {
          row.style.display = 'none'
        }
      }
    })
  }
  
  addProduct(event) {
    const button = event.currentTarget
    const productId = button.dataset.productId
    const quoteId = button.dataset.quoteId
    
    // Get quantity from the related input field
    const quantityInput = document.getElementById(`quantity-${productId}`)
    const quantity = quantityInput ? parseInt(quantityInput.value, 10) : 1
    
    // Validate quantity
    if (isNaN(quantity) || quantity < 1) {
      this.showNotification('error', 'La cantidad debe ser un número mayor a 0')
      return
    }
    
    // Prevent double clicks
    button.disabled = true
    
    fetch(`/quotes/${quoteId}/add_product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ 
        product_id: productId,
        quantity: quantity
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      if (data.success) {
        // Reload the page to show the updated product list
        window.location.reload()
      } else {
        this.showNotification('error', data.message || 'Error al agregar el producto')
        button.disabled = false
      }
    })
    .catch(error => {
      this.showNotification('error', 'Error al agregar el producto. Intente nuevamente.')
      console.error('Error:', error)
      button.disabled = false
    })
  }
  
  removeProduct(event) {
    if (!confirm('¿Está seguro que desea eliminar este producto de la cotización?')) {
      return
    }
    
    const button = event.currentTarget
    const quoteId = button.dataset.quoteId
    const productId = button.dataset.productId
    
    fetch(`/quotes/${quoteId}/remove_product`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ product_id: productId })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      if (data.success) {
        // Remove the row from the table
        button.closest('tr').remove()
        
        // If no products left, reload to show empty state
        const productRows = document.querySelectorAll('#products-table tbody tr')
        if (productRows.length === 0) {
          window.location.reload()
        }
      } else {
        this.showNotification('error', data.message || 'Error al eliminar el producto')
      }
    })
    .catch(error => {
      this.showNotification('error', 'Error al eliminar el producto. Intente nuevamente.')
      console.error('Error:', error)
    })
  }
  
  showNotification(type, message) {
    if (this.hasNotificationTarget) {
      const notification = this.notificationTarget
      notification.textContent = message
      notification.className = `alert alert-${type === 'error' ? 'danger' : 'success'} mt-3`
      notification.classList.remove('d-none')
      
      // Hide after 5 seconds
      setTimeout(() => {
        notification.classList.add('d-none')
      }, 5000)
    }
  }
} 