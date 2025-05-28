<template>
  <div class="quote-form">
    <div class="row">
      <div class="col-lg-7">
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
                      <input type="text" class="form-control" id="project_name" v-model="form.project_name" required>
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
                        <input type="text" class="form-control text-start" id="customer_name" v-model="form.customer_name" required>
                        <button type="button" class="btn btn-outline-secondary" @click="searchCustomersInline" :title="'Search customer'">
                          <i class="fas fa-search"></i>
                        </button>
                      </div>
                      <small v-if="customerSearch.error" class="text-danger">{{ customerSearch.error }}</small>
                      <small v-if="customerSearch.loading" class="text-info">{{ translations.searching_customers }}</small>
                    </div>
                  </div>
                  <div class="col-md-6">
                    <div class="mb-3">
                      <label for="organization" class="form-label">{{ translations.organization }}</label>
                      <select v-if="customerSearch.results.length > 0" 
                              class="form-select" 
                              id="organization" 
                              v-model="selectedCustomerId"
                              @change="handleCustomerSelection">
                        <option value="">{{ translations.select_organization }}</option>
                        <option v-for="customer in customerSearch.results" 
                                :key="customer.id" 
                                :value="customer.id">
                          {{ customer.org_name || translations.no_organization }}
                        </option>
                      </select>
                      <input v-else type="text" class="form-control" id="organization" v-model="form.organization" required>
                    </div>
                  </div>
                </div>
                <div class="row">
                  <div class="col-md-6">
                    <div class="mb-3">
                      <label for="email" class="form-label">{{ translations.email }}</label>
                      <input type="email" class="form-control" id="email" v-model="form.email">
                    </div>
                  </div>
                  <div class="col-md-6">
                    <div class="mb-3">
                      <label for="telephone" class="form-label">{{ translations.telephone }}</label>
                      <input type="text" class="form-control" id="telephone" v-model="form.telephone">
                    </div>
                  </div>
                </div>
                <div class="row">
                  <div class="col-12">
                    <div class="mb-3">
                      <label for="comments" class="form-label">{{ translations.comments }}</label>
                      <textarea rows="3" class="form-control" id="comments" v-model="form.comments"></textarea>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>

      <div class="col-lg-5">
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
                <select 
                  id="product-select" 
                  class="form-select" 
                  v-model="selectedProductId"
                >
                  <option value="">-- {{ translations.select_product }} --</option>
                  <option 
                    v-for="product in filteredProducts" 
                    :key="product.id" 
                    :value="product.id"
                  >
                    {{ product.description }} - {{ formatCurrency(product.data && product.data.pricing && product.data.pricing.total_price || 0) }}
                  </option>
                </select>
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
        <!-- Selected Products Card - Now in the middle -->
          <div class="card mb-4">
            <div class="card-header">
              <h5 class="mb-0">{{ translations.selected_products }}</h5>
            </div>
            <div class="card-body">
              <div v-if="selectedProducts.length === 0" class="alert alert-info">
                {{ translations.no_selected_products }}
              </div>
              <div v-else>
                <div class="table-responsive">
                  <table class="table table-sm">
                    <thead>
                      <tr>
                        <th style="width: 70%">{{ translations.product }}</th>
                        <th>{{ translations.price }}</th>
                        <th style="width: 40px"></th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(product, index) in selectedProducts" :key="product.id">
                        <td class="text-wrap">{{ product.name }}</td>
                        <td>{{ formatCurrency(product.price) }}</td>
                        <td>
                          <button type="button" class="btn btn-sm btn-danger" @click="removeProduct(index)">
                            <i class="fas fa-trash"></i>
                          </button>
                        </td>
                      </tr>
                    </tbody>
                  </table>
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
              <table class="table table-sm">
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
              <small v-if="customerSearch.error" class="text-danger">{{ customerSearch.error }}</small>
            </div>
            
            <div v-if="customerSearch.loading" class="d-flex justify-content-center my-3">
              <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">{{ translations.loading }}</span>
              </div>
            </div>
            
            <div v-if="customerSearch.error" class="alert alert-danger bg-dark text-danger border-danger">
              {{ customerSearch.error }}
            </div>
            
            <div v-if="customerSearch.noResults" class="alert alert-info bg-dark text-light border-secondary">
              {{ translations.no_customers_found }}
            </div>
            
            <div v-if="customerSearch.results.length > 0" class="table-responsive">
              <table class="table table-hover table-dark">
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
</template>

<script>
export default {
  name: 'QuoteForm',
  
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
      pipedriveApiConfigured: false
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
        this.customerSearch.error = 'Ingrese al menos 3 caracteres para buscar';
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
    
    saveQuote() {
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
        this.customerSearch.error = 'Ingrese al menos 3 caracteres para buscar';
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
      
      // Find the selected customer from the results
      const selectedCustomer = this.customerSearch.results.find(
        customer => customer.id == this.selectedCustomerId
      );
      
      if (selectedCustomer) {
        // Populate the form with customer information
        this.form.customer_name = selectedCustomer.name || '';
        this.form.organization = selectedCustomer.org_name || '';
        this.form.email = selectedCustomer.email || '';
        this.form.telephone = selectedCustomer.phone || '';
      }
    },
    
    addSelectedProduct() {
      if (!this.selectedProductId) {
        return;
      }
      
      // Find the selected product from the availableProducts array
      const selectedProduct = this.availableProducts.find(product => product.id === this.selectedProductId);
      
      if (selectedProduct) {
        this.addProduct(selectedProduct);
        // Reset the selection after adding
        this.selectedProductId = '';
      }
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
    // Listen for the external event to add products
    if (window.quoteFormEventBus) {
      window.quoteFormEventBus.on('add-product', (product) => {
        this.addProduct(product);
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
    // Remove event listener when component is destroyed
    const saveButton = document.getElementById('save-quote-button');
    if (saveButton) {
      saveButton.removeEventListener('click', this.saveQuote);
    }
  }
}
</script>

<style scoped>
.quote-form {
  position: relative;
  height: auto;
  overflow: visible;
}

.row {
  margin-right: -15px;
  margin-left: -15px;
}

.col-lg-7,
.col-lg-5 {
  padding-right: 15px;
  padding-left: 15px;
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

.quote-form {
  padding: 2rem;
}
.quote-form .card {
  border-left: none !important;
  border: none !important;
  box-shadow: none !important;
}
</style> 