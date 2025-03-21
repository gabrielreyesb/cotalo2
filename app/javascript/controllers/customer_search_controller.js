import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["results", "query", "spinner", "noResults", "error"]
  
  connect() {
    // Initialize the controller
  }
  
  search(event) {
    event.preventDefault()
    
    const query = this.queryTarget.value.trim()
    if (query.length < 3) {
      return
    }
    
    this.showSpinner()
    this.hideResults()
    this.hideNoResults()
    this.hideError()
    
    fetch('/quotes/search_customer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ query: query })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      this.hideSpinner()
      
      if (data.error) {
        this.showError(data.error)
        return
      }
      
      if (data.customers && data.customers.length > 0) {
        this.populateResults(data.customers)
        this.showResults()
      } else {
        this.showNoResults()
      }
    })
    .catch(error => {
      this.hideSpinner()
      this.showError('Error al buscar clientes. Intente nuevamente.')
      console.error('Error:', error)
    })
  }
  
  populateResults(customers) {
    const resultsContainer = this.resultsTarget
    resultsContainer.innerHTML = ''
    
    customers.forEach(customer => {
      const row = document.createElement('tr')
      
      const nameCell = document.createElement('td')
      nameCell.textContent = customer.name || 'N/A'
      row.appendChild(nameCell)
      
      const orgCell = document.createElement('td')
      orgCell.textContent = customer.org_name || 'N/A'
      row.appendChild(orgCell)
      
      const emailCell = document.createElement('td')
      emailCell.textContent = customer.email || 'N/A'
      row.appendChild(emailCell)
      
      const phoneCell = document.createElement('td')
      phoneCell.textContent = customer.phone || 'N/A'
      row.appendChild(phoneCell)
      
      const actionCell = document.createElement('td')
      const selectButton = document.createElement('button')
      selectButton.className = 'btn btn-sm btn-primary'
      selectButton.textContent = 'Seleccionar'
      selectButton.addEventListener('click', () => this.selectCustomer(customer))
      actionCell.appendChild(selectButton)
      row.appendChild(actionCell)
      
      resultsContainer.appendChild(row)
    })
  }
  
  selectCustomer(customer) {
    // Fill form fields with selected customer data
    document.getElementById('quote_customer_name').value = customer.name || ''
    document.getElementById('quote_organization').value = customer.org_name || ''
    document.getElementById('quote_email').value = customer.email || ''
    document.getElementById('quote_telephone').value = customer.phone || ''
    
    // Close the modal
    const modal = document.getElementById('customerSearchModal')
    const bootstrapModal = bootstrap.Modal.getInstance(modal)
    bootstrapModal.hide()
  }
  
  showSpinner() {
    this.spinnerTarget.classList.remove('d-none')
  }
  
  hideSpinner() {
    this.spinnerTarget.classList.add('d-none')
  }
  
  showResults() {
    this.resultsTarget.closest('.table-responsive').classList.remove('d-none')
  }
  
  hideResults() {
    this.resultsTarget.closest('.table-responsive').classList.add('d-none')
  }
  
  showNoResults() {
    this.noResultsTarget.classList.remove('d-none')
  }
  
  hideNoResults() {
    this.noResultsTarget.classList.add('d-none')
  }
  
  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove('d-none')
  }
  
  hideError() {
    this.errorTarget.classList.add('d-none')
  }
} 