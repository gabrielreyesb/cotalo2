<template>
  <div class="quote-form">
    <div class="product-form-container">
      <div class="row g-0">
        <!-- Main Form Column -->
        <div class="col-12 col-lg-9">
          <form @submit.prevent="saveQuote">
            <div class="green-accent-panel">
              <div class="card mb-4">
                <div class="card-header">
                  <h5 class="mb-0">{{ translations.quote_info }}</h5>
                </div>
                <div class="card-body">
                  <div class="row">
                    <div class="col-md-6">
                      <div class="mb-3">
                        <label for="project_name" class="form-label">{{ translations.project_name }}</label>
                        <input type="text" class="form-control" id="project_name" v-model="form.project_name" required autocomplete="off">
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="green-accent-panel">
              <div class="card mb-4">
                <div class="card-header">
                  <h5 class="mb-0">{{ translations.customer_info }}</h5>
                </div>
                <div class="card-body">
                  <div class="row">
                    <div class="col-md-6">
                      <div class="mb-3">
                        <label for="customer_name" class="form-label">{{ translations.customer_name }}</label>
                        <div class="input-group">
                          <input type="text" class="form-control text-start" id="customer_name" v-model="form.customer_name" required autocomplete="off">
                          <button type="button" class="btn btn-outline-secondary" @click="searchCustomersInline" :title="'Search customer'">
                            <i class="fas fa-search"></i>
                          </button>
                        </div>
                        <small v-if="customerSearch.loading" class="text-info">{{ translations.searching_customers }}</small>
                      </div>
                    </div>
                    <div class="col-md-6">
                      <div class="mb-3">
                        <label for="organization" class="form-label">{{ translations.organization }}</label>
                        <multiselect
                          v-if="customerSearch.results.length > 0"
                          v-model="selectedCustomerId"
                          :options="customerSearch.results"
                          :track-by="'id'"
                          :label="'org_name'"
                          :placeholder="translations.select_organization"
                          :searchable="true"
                          :allow-empty="true"
                          :clear-on-select="true"
                          :close-on-select="true"
                          :show-labels="false"
                        />
                        <input v-else type="text" class="form-control" id="organization" v-model="form.organization" required autocomplete="off">
                      </div>
                    </div>
                  </div>
                  <div class="row">
                    <div class="col-md-6">
                      <div class="mb-3">
                        <label for="email" class="form-label">{{ translations.email }}</label>
                        <input type="email" class="form-control" id="email" v-model="form.email" autocomplete="off">
                      </div>
                    </div>
                    <div class="col-md-6">
                      <div class="mb-3">
                        <label for="telephone" class="form-label">{{ translations.telephone }}</label>
                        <input type="text" class="form-control" id="telephone" v-model="form.telephone" autocomplete="off">
                      </div>
                    </div>
                  </div>
                  <div class="row">
                    <div class="col-12">
                      <div class="mb-3">
                        <label for="comments" class="form-label">{{ translations.comments }}</label>
                        <textarea rows="3" class="form-control" id="comments" v-model="form.comments" autocomplete="off"></textarea>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
        <!-- Sidebar Column -->
        <div class="col-12 col-lg-3 mt-3 mt-lg-0 ps-lg-4">
          <div class="green-accent-panel">
            <div class="card mb-4">
              <div class="card-header">
                <h5 class="mb-0">{{ translations.add_product }}</h5>
              </div>
              <div class="card-body">
                <div class="mb-3">
                  <label for="product-search" class="form-label">{{ translations.search_product }}</label>
                  <input 
                    type="text" 
                    id="product-search" 
                    class="form-control" 
                    v-model="productSearch" 
                    :placeholder="translations.search_by_description"
                  />
                </div>
                
                <div class="mb-3">
                  <label for="product-select" class="form-label">{{ translations.select_product }}</label>
                  <multiselect
                    v-model="selectedProductId"
                    :options="filteredProducts"
                    :track-by="'id'"
                    :label="'description'"
                    :placeholder="translations.select_product"
                    :searchable="true"
                    :allow-empty="true"
                    :clear-on-select="true"
                    :close-on-select="true"
                    :show-labels="false"
                  />
                </div>
                
                <div class="d-grid">
                  <button 
                    type="button" 
                    class="btn btn-primary" 
                    @click="addSelectedProduct()" 
                    :disabled="!selectedProductId"
                  >
                    <i class="fas fa-plus"></i> {{ translations.add_to_quote }}
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <div class="green-accent-panel">
            <div class="card mb-4">
              <div class="card-header">
                <h5 class="mb-0">{{ translations.selected_products }}</h5>
              </div>
              <div class="card-body">
                <div v-if="selectedProducts.length === 0" class="alert alert-info">
                  {{ translations.no_selected_products }}
                </div>
                <div v-else>
                  <!-- Desktop Table -->
                  <div class="d-none d-md-block">
                    <table class="table table-hover">
                      <thead>
                        <tr>
                          <th style="width: 70%">{{ translations.product }}</th>
                          <th class="text-end">{{ translations.price }}</th>
                          <th style="width: 72px"></th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(product, index) in selectedProducts" :key="product.id">
                          <td class="text-wrap">{{ product.name }}</td>
                          <td class="text-end align-middle" style="white-space: nowrap; overflow: hidden;">{{ formatCurrency(product.price) }}</td>
                          <td class="align-middle ps-3">
                            <button type="button" class="btn btn-sm btn-danger ms-2" @click="removeProduct(index)">
                              <i class="fas fa-trash"></i>
                            </button>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                  <!-- Mobile Cards -->
                  <div class="d-md-none">
                    <div v-for="(product, index) in selectedProducts" :key="product.id" class="card mb-3 shadow-sm mx-2 mt-3" style="overflow: hidden;">
                      <div class="card-body p-3">
                        <!-- Product name -->
                        <h6 class="card-title mb-2 d-flex align-items-center">
                          <i class="fa fa-box me-1"></i>
                          <span class="fw-bold">{{ product.name }}</span>
                        </h6>
                        <div class="d-flex align-items-center justify-content-between">
                          <div class="d-flex align-items-center">
                            <i class="fa fa-dollar-sign me-1"></i>
                            <span class="fs-6">{{ formatCurrency(product.price) }}</span>
                          </div>
                          <button type="button" class="btn btn-sm btn-danger ms-2" @click="removeProduct(index)">
                            <i class="fas fa-trash"></i>
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Totals Card - Still at the bottom -->
          <div class="green-accent-panel" v-if="selectedProducts.length > 0">
            <div class="card mb-4">
              <div class="card-header">
                <h5 class="mb-0">{{ translations.price_summary }}</h5>
              </div>
              <div class="card-body">
                <table class="table table-hover">
                  <tbody>
                    <tr>
                      <th>{{ translations.subtotal }}</th>
                      <td class="text-end">{{ formatCurrency(totals.subtotal) }}</td>
                    </tr>
                    <tr>
                      <th>{{ translations.tax }} ({{ totals.taxPercentage }}%):</th>
                      <td class="text-end">{{ formatCurrency(totals.tax) }}</td>
                    </tr>
                    <tr class="fw-bold">
                      <th>{{ translations.total }}</th>
                      <td class="text-end">{{ formatCurrency(totals.total) }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Customer Search Modal -->
      <div class="modal" tabindex="-1" v-if="showCustomerSearchModal">
        <div class="modal-dialog modal-lg">
          <div class="modal-content bg-dark text-light">
            <div class="modal-header border-secondary">
              <h5 class="modal-title">{{ translations.search_customer }}</h5>
              <button type="button" class="btn-close btn-close-white" @click="showCustomerSearchModal = false"></button>
            </div>
            <div class="modal-body">
              <div class="mb-3">
                <label for="customerSearchQuery" class="form-label">{{ translations.customer_name }}</label>
                <div class="input-group">
                  <input type="text" class="form-control bg-dark text-light border-secondary" id="customerSearchQuery" v-model="customerSearch.query" :placeholder="translations.enter_at_least_3_chars">
                  <button class="btn btn-primary" @click="searchCustomers" :disabled="customerSearch.loading || customerSearch.query.length < 3" :title="'Search customer'">{{ translations.search }}</button>
                </div>
                <small class="form-text text-muted">{{ translations.enter_at_least_3_chars }}</small>
              </div>
              
              <div v-if="customerSearch.loading" class="d-flex justify-content-center my-3">
                <div class="spinner-border text-primary" role="status">
                  <span class="visually-hidden">{{ translations.loading }}</span>
                </div>
              </div>
              
              <div v-if="customerSearch.noResults" class="alert alert-info bg-dark text-light border-secondary">
                {{ translations.no_customers_found }}
              </div>
              
              <div v-if="customerSearch.results.length > 0" class="table-responsive">
                <table class="table table-hover">
                  <thead>
                    <tr>
                      <th>{{ translations.name }}</th>
                      <th>{{ translations.organization }}</th>
                      <th>{{ translations.email }}</th>
                      <th>{{ translations.telephone }}</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="customer in customerSearch.results" :key="customer.id">
                      <td>{{ customer.name || 'N/A' }}</td>
                      <td>{{ customer.org_name || 'N/A' }}</td>
                      <td>{{ customer.email || 'N/A' }}</td>
                      <td>{{ customer.phone || 'N/A' }}</td>
                      <td>
                        <button type="button" class="btn btn-sm btn-primary" @click="selectCustomer(customer)">
                          {{ translations.select }}
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div class="modal-footer border-secondary">
              <button type="button" class="btn btn-secondary" @click="showCustomerSearchModal = false">{{ translations.close }}</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Multiselect from 'vue-multiselect'
import 'vue-multiselect/dist/vue-multiselect.min.css'

export default {
  name: 'QuoteForm',
  components: {
    Multiselect,
  },
  props: {
    availableProducts: {
      type: Array,
      default: () => []
    },
    quote: {
      type: Object,
      default: () => ({})
    },
    editMode: {
      type: Boolean,
      default: false
    },
    onSave: {
      type: Function,
      default: () => {}
    },
    onCancel: {
      type: Function,
      default: () => {}
    },
    translations: {
      type: Object,
      required: true
    }
  },
  
  data() {
    return {
      form: {
        project_name: '',
        customer_name: '',
        organization: '',
        email: '',
        telephone: '',
        comments: ''
      },
      selectedProducts: [],
      totals: {
        subtotal: 0,
        taxPercentage: 16, // Default to 16% - Mexico
        tax: 0,
        total: 0
      },
      showCustomerSearchModal: false,
      customerSearch: {
        query: '',
        loading: false,
        error: null,
        results: [],
        noResults: false
      },
      productSearch: '',
      selectedCustomerId: '',
      selectedProductId: '',
      pipedriveApiConfigured: false,
      debugTheme: document.body.getAttribute('data-theme'),
      debugCardBg: getComputedStyle(document.body).getPropertyValue('--card-bg')
    }
  },
  
  computed: {
    filteredProducts() {
      if (!this.productSearch) {
        return this.availableProducts.map(product => ({
          ...product,
          tempQuantity: 1
        }));
      }
      
      const searchTerm = this.productSearch.toLowerCase();
      return this.availableProducts
        .filter(product => {
          if (product.formatted_description) {
            return product.formatted_description.toLowerCase().includes(searchTerm);
          } else if (product.description) {
            return product.description.toLowerCase().includes(searchTerm);
          }
          return false;
        })
        .map(product => ({
          ...product,
          tempQuantity: 1
        }));
    }
  },
  
  watch: {
    quote: {
      handler(newQuote) {
        if (this.editMode && newQuote && Object.keys(newQuote).length) {
          // Set basic form data
          this.form = {
            project_name: newQuote.project_name || '',
            customer_name: newQuote.customer_name || '',
            organization: newQuote.organization || '',
            email: newQuote.email || '',
            telephone: newQuote.telephone || '',
            comments: newQuote.comments || ''
          };
          
          // Get tax percentage from the quote data
          if (newQuote.data && newQuote.data.totals) {
            this.totals.taxPercentage = newQuote.data.totals.tax_percentage || 16;
          }
          
          // Load products if available
          if (newQuote.quote_products && newQuote.quote_products.length) {
            this.selectedProducts = newQuote.quote_products.map(qp => {
              // Get price from the product's data.pricing
              let price = 0;
              if (qp.product && qp.product.data && qp.product.data.pricing) {
                price = parseFloat(qp.product.data.pricing.total_price || 0);
              }
              
              return {
                id: qp.product_id,
                name: qp.product.description || `Product ${qp.product_id}`,
                price: price,
                quantity: qp.quantity || 1
              };
            });
            
            // Calculate totals
            this.calculateTotals();
          }
        }
      },
      immediate: true
    },
    selectedCustomerId(newVal, oldVal) {
      this.handleCustomerSelection();
    }
  },
  
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('es-MX', { 
        style: 'currency', 
        currency: 'MXN'
      }).format(value || 0);
    },
    
    calculateTotals() {
      // Calculate subtotal
      const subtotal = this.selectedProducts.reduce((sum, product) => {
        return sum + (product.price * product.quantity);
      }, 0);
      
      // Calculate tax
      const tax = subtotal * (this.totals.taxPercentage / 100);
      
      // Calculate total
      const total = subtotal + tax;
      
      // Update totals
      this.totals.subtotal = subtotal;
      this.totals.tax = tax;
      this.totals.total = total;
    },
    
    addProduct(product) {
      // Check if product is already in the list
      const existingProduct = this.selectedProducts.find(p => p.id === product.id);
      
      if (existingProduct) {
        // Product already exists, don't add it again
        return;
      }
        
      // Get price from the product's data.pricing
      let price = 0;
      if (product.data && product.data.pricing && product.data.pricing.total_price) {
        price = parseFloat(product.data.pricing.total_price);
      }
      
      // Add new product to the list
      this.selectedProducts.push({
        id: product.id,
        name: product.description || product.formatted_description || `Product ${product.id}`,
        price: price,
        quantity: 1  // Keep quantity for backend calculations
      });
      
      // Calculate totals
      this.calculateTotals();
    },
    
    removeProduct(index) {
      this.selectedProducts.splice(index, 1);
      this.calculateTotals();
    },
    
    searchCustomers() {
      // Validate query
      if (this.customerSearch.query.length < 3) {
        window.showWarning('Ingrese al menos 3 caracteres para buscar');
        return;
      }
      
      // Reset states
      this.customerSearch.loading = true;
      this.customerSearch.error = null;
      this.customerSearch.results = [];
      this.customerSearch.noResults = false;
      
      // Get CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
      
      // Make API request
      fetch('/quotes/search_customer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ query: this.customerSearch.query })
      })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.json();
      })
      .then(data => {
        this.customerSearch.loading = false;
        
        if (data.error) {
          this.customerSearch.error = data.error;
          return;
        }
        
        if (data.customers && data.customers.length > 0) {
          this.customerSearch.results = data.customers;
        } else {
          this.customerSearch.noResults = true;
        }
      })
      .catch(error => {
        this.customerSearch.loading = false;
        this.customerSearch.error = 'Error al buscar clientes. Intente nuevamente: ' + error.message;
        console.error('Error:', error);
      });
    },
    
    selectCustomer(customer) {
      this.form.customer_name = customer.name || '';
      this.form.organization = customer.org_name || '';
      this.form.email = customer.email || '';
      this.form.telephone = customer.phone || '';
      
      // Close modal
      this.showCustomerSearchModal = false;
    },
    
    validateQuote() {
      const { project_name, customer_name, organization, email, telephone } = this.form;
      
      if (!project_name || !project_name.trim()) {
        window.showWarning(this.translations.validations.project_name_required);
        return false;
      }
      
      if (!customer_name || !customer_name.trim()) {
        window.showWarning(this.translations.validations.customer_name_required);
        return false;
      }
      
      if (!organization || !organization.trim()) {
        window.showWarning(this.translations.validations.organization_required);
        return false;
      }

      if (!email || !email.trim()) {
        window.showWarning(this.translations.validations.email_required);
        return false;
      }

      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        window.showWarning(this.translations.validations.email_invalid);
        return false;
      }

      if (!telephone || !telephone.trim()) {
        window.showWarning(this.translations.validations.telephone_required);
        return false;
      }

      if (this.selectedProducts.length === 0) {
        window.showWarning(this.translations.validations.at_least_one_product);
        return false;
      }
      
      return true; // All validations passed
    },

    saveQuote() {
      if (!this.validateQuote()) {
        return;
      }

      // Create a form data object to submit
      const formData = {
        form: this.form,
        selectedProducts: this.selectedProducts,
        totals: this.totals
      };
      
      // Call the save function from props
      this.onSave(formData);
    },
    
    cancelQuote() {
      // Call the cancel function from props
      this.onCancel();
    },
    
    searchCustomersInline() {
      // Validate query
      if (!this.form.customer_name || this.form.customer_name.length < 3) {
        window.showWarning('Ingrese al menos 3 caracteres para buscar');
        return;
      }
      
      // Reset states
      this.customerSearch.loading = true;
      this.customerSearch.error = null;
      this.customerSearch.results = [];
      this.customerSearch.noResults = false;
      this.selectedCustomerId = '';
      
      // Get CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
      
      // Make API request
      fetch('/quotes/search_customer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ query: this.form.customer_name })
      })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.json();
      })
      .then(data => {
        this.customerSearch.loading = false;
        
        if (data.error) {
          this.customerSearch.error = data.error;
          return;
        }
        
        if (data.customers && data.customers.length > 0) {
          this.customerSearch.results = data.customers;
        } else {
          this.customerSearch.noResults = true;
        }
      })
      .catch(error => {
        this.customerSearch.loading = false;
        this.customerSearch.error = 'Error al buscar clientes. Intente nuevamente: ' + error.message;
        console.error('Error:', error);
      });
    },
    
    handleCustomerSelection() {
      if (!this.selectedCustomerId) {
        return;
      }
      // selectedCustomerId is the full customer object
      const selectedCustomer = this.selectedCustomerId;
      if (selectedCustomer) {
        this.form.customer_name = selectedCustomer.name || '';
        this.form.organization = selectedCustomer.org_name || selectedCustomer.company || selectedCustomer.organization || '';
        this.form.email = selectedCustomer.email || '';
        this.form.telephone = selectedCustomer.phone || '';
      }
    },
    
    addSelectedProduct() {
      if (!this.selectedProductId) {
        return;
      }
      // selectedProductId is now the product object
      this.addProduct(this.selectedProductId);
      this.selectedProductId = '';
    },
    
    checkPipedriveApiStatus() {
      fetch('/api/v1/verify_pipedrive', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
      .then(response => response.json())
      .then(data => {
        this.pipedriveApiConfigured = data.success;
      })
      .catch(error => {
        console.error('Error checking Pipedrive API status:', error);
        this.pipedriveApiConfigured = false;
      });
    }
  },
  
  mounted() {
    console.log('QuoteForm.vue script loaded');
    // Listen for the external event to add products
    if (window.quoteFormEventBus) {
      window.quoteFormEventBus.on('add-product', (product) => {
        this.addProduct(product);
      });

      // Listen for validation error events and display them as toasts
      window.quoteFormEventBus.on('set-validation-errors', (errors) => {
        if (Array.isArray(errors)) {
          errors.forEach(error => window.showError(error));
        } else if (typeof errors === 'object') {
          Object.values(errors).flat().forEach(error => window.showError(error));
        }
      });

      // Listen for a success event
      window.quoteFormEventBus.on('quote-success', (message) => {
        window.showSuccess(message);
      });
    }

    // Add event listener for the save button in the subnavbar
    const saveButton = document.getElementById('save-quote-button');
    if (saveButton) {
      saveButton.addEventListener('click', this.saveQuote);
    }

    // Check Pipedrive API key status
    this.checkPipedriveApiStatus();
  },

  beforeDestroy() {
    // Remove event listeners when component is destroyed
    if (window.quoteFormEventBus) {
      window.quoteFormEventBus.events['add-product'] = [];
      window.quoteFormEventBus.events['set-validation-errors'] = [];
      window.quoteFormEventBus.events['quote-success'] = [];
    }

    const saveButton = document.getElementById('save-quote-button');
    if (saveButton) {
      saveButton.removeEventListener('click', this.saveQuote);
    }
  }
}
</script>

<style>
.quote-form {
  position: relative;
  height: auto;
  overflow: visible;
  padding: 0;
}

/* Form controls with dark theme */
.form-select, 
.form-control {
  color: #e1e1e1;
  background-color: #2c3136;
  border: 1px solid #495057;
  border-radius: 4px;
}

.form-select:focus {
  border-color: #42b983;
  box-shadow: 0 0 0 0.25rem rgba(66, 185, 131, 0.25);
}

.btn-primary {
  background-color: #42b983;
  border-color: #42b983;
}

.btn-primary:hover {
  background-color: #3aa876;
  border-color: #39a06e;
}

.btn-primary:disabled {
  background-color: #2a7550;
  border-color: #2a7550;
}

/* Table hover styles */
.table-hover tbody tr:hover {
  background-color: rgba(66, 185, 131, 0.1) !important;
}

.form-select {
  font-size: 1rem !important;
  padding: 0.375rem 0.75rem !important;
  line-height: 1.5 !important;
  min-width: 0;
}
</style> 