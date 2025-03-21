<template>
  <div class="general-tab">
    <form @submit.prevent="saveProduct">
      <div class="row">
        <div class="col-md-6">
          <div class="card mb-3">
            <div class="card-body">
              
              <div class="mb-3">
                <label for="product-description" class="form-label">Descripción del producto</label>
                <input 
                  type="text" 
                  id="product-description" 
                  class="form-control" 
                  v-model="form.description" 
                  @input="emitFormChanges"
                  required
                />
              </div>
              
              <div class="mb-3">
                <label for="product-quantity" class="form-label">Cantidad</label>
                <input 
                  type="number" 
                  id="product-quantity" 
                  class="form-control" 
                  v-model.number="form.data.general_info.quantity" 
                  @input="emitFormChanges"
                  min="1" 
                  required
                />
              </div>
              
              <div class="row">
                <div class="col-md-6">
                  <div class="mb-3">
                    <label for="product-width" class="form-label">Ancho (cm)</label>
                    <input 
                      type="number" 
                      id="product-width" 
                      class="form-control" 
                      v-model.number="form.data.general_info.width" 
                      @input="emitFormChanges"
                      min="0" 
                      step="0.1"
                    />
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="mb-3">
                    <label for="product-length" class="form-label">Largo (cm)</label>
                    <input 
                      type="number" 
                      id="product-length" 
                      class="form-control" 
                      v-model.number="form.data.general_info.length" 
                      @input="emitFormChanges"
                      min="0" 
                      step="0.1"
                    />
                  </div>
                </div>
              </div>
              
              <div class="mb-3">
                <label for="product-inner-measurements" class="form-label">Medidas internas</label>
                <input 
                  type="text" 
                  id="product-inner-measurements" 
                  class="form-control" 
                  v-model="form.data.general_info.inner_measurements"
                  @input="emitFormChanges"
                />
              </div>
            </div>
          </div>
        </div>
        
        <div class="col-md-6">
          <div class="card mb-3">
            <div class="card-body">
              
              <div class="mb-3">
                <label for="customer-name" class="form-label">Nombre del cliente</label>
                <div class="input-group">
                  <input 
                    type="text" 
                    id="customer-name" 
                    class="form-control" 
                    v-model="form.data.general_info.customer_name"
                    @input="emitFormChanges"
                  />
                  <button 
                    type="button" 
                    class="btn btn-primary input-group-text"
                    @click="searchCustomer"
                    :disabled="loading"
                  >
                    <span v-if="loading" class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
                    Buscar en Pipedrive
                  </button>
                </div>
              </div>
              
              <div class="mb-3">
                <label for="customer-organization" class="form-label">Organización</label>
                <select 
                  v-if="showOrganizationSelect"
                  id="customer-organization" 
                  class="form-select bg-dark text-light border-secondary" 
                  v-model="selectedOrganization"
                  @change="onOrganizationSelected"
                >
                  <option value="">Seleccione una organización...</option>
                  <option v-for="org in uniqueOrganizations" :key="org" :value="org">
                    {{ org }}
                  </option>
                </select>
                <input 
                  v-else
                  type="text" 
                  id="customer-organization" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_organization"
                  @input="emitFormChanges"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-email" class="form-label">Email</label>
                <input 
                  type="email" 
                  id="customer-email" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_email"
                  @input="emitFormChanges"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-phone" class="form-label">Teléfono</label>
                <input 
                  type="tel" 
                  id="customer-phone" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_phone"
                  @input="emitFormChanges"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="card mb-3">
        <div class="card-body">
          
          <div class="mb-3">
            <label for="product-comments" class="form-label">Comentarios</label>
            <textarea 
              id="product-comments" 
              class="form-control" 
              v-model="form.data.general_info.comments" 
              @input="emitFormChanges"
              rows="3"
            ></textarea>
          </div>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'GeneralTab',
  props: {
    product: {
      type: Object,
      required: true
    },
    isNew: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      form: {
        description: '',
        data: {
          general_info: {
            width: null,
            length: null,
            inner_measurements: '',
            quantity: 1,
            customer_name: '',
            customer_organization: '',
            customer_email: '',
            customer_phone: '',
            comments: ''
          }
        }
      },
      saving: false,
      loading: false,
      searchResults: [],
      showOrganizationSelect: false,
      uniqueOrganizations: [],
      selectedOrganization: ''
    };
  },
  watch: {
    product: {
      handler(product) {
        if (product) {
          this.initFormData();
        }
      },
      immediate: true,
      deep: true
    }
  },
  methods: {
    initFormData() {
      // Default empty structure in case product data is incomplete
      const defaultGeneralInfo = {
        width: null,
        length: null,
        inner_measurements: '',
        quantity: 1,
        customer_name: '',
        customer_organization: '',
        customer_email: '',
        customer_phone: '',
        comments: ''
      };
      
      // Create deep copy to avoid modifying props directly
      // Ensure data structure is complete even if product is partially initialized
      this.form = {
        description: this.product && this.product.description ? this.product.description : '',
        data: {
          general_info: { 
            ...defaultGeneralInfo,
            ...(this.product && this.product.data && this.product.data.general_info ? this.product.data.general_info : {})
          }
        }
      };
      
      // Ensure minimum value for quantity
      if (!this.form.data.general_info.quantity || this.form.data.general_info.quantity < 1) {
        this.form.data.general_info.quantity = 1;
      }
    },
    emitFormChanges() {
      // Update the parent component with the current form data in real-time
      const oldQuantity = this.product?.data?.general_info?.quantity;
      const oldWidth = this.product?.data?.general_info?.width;
      const oldLength = this.product?.data?.general_info?.length;
      
      const newQuantity = this.form.data.general_info.quantity;
      const newWidth = this.form.data.general_info.width;
      const newLength = this.form.data.general_info.length;
      
      // Create a copy for the update, ensuring we have a valid data structure
      const updatedProduct = {
        description: this.form.description,
        data: {
          ...(this.product && this.product.data ? this.product.data : {}),
          general_info: { ...this.form.data.general_info }
        }
      };
      
      // Just update the product in the parent, don't trigger save
      this.$emit('update:product', updatedProduct);
    },
    saveProduct() {
      this.saving = true;
      
      // Create a copy for the update, ensuring we have a valid data structure
      const updatedProduct = {
        description: this.form.description,
        data: {
          ...(this.product && this.product.data ? this.product.data : {}),
          general_info: { ...this.form.data.general_info }
        }
      };
      
      // Emit the appropriate event based on whether this is a new product or an existing one
      if (this.isNew) {
        this.$emit('create:product', updatedProduct);
      } else {
        this.$emit('update:product', updatedProduct);
      }
      
      this.saving = false;
    },
    searchCustomer() {
      if (!this.form.data.general_info.customer_name) {
        alert("Por favor, introduce un nombre de cliente para buscar");
        return;
      }
      
      this.loading = true;
      
      // Use native fetch instead of axios
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
      
      fetch('/api/v1/search_customer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          customer_name: this.form.data.general_info.customer_name
        })
      })
      .then(response => {
        if (!response.ok) {
          throw new Error(`Error: ${response.status} ${response.statusText}`);
        }
        return response.json();
      })
      .then(data => {
        if (data.error) {
          throw new Error(data.error);
        }
        
        // Handle search results
        this.handleSearchResults(data.results || []);
      })
      .catch(error => {
        alert(`Error al buscar cliente: ${error.message}. Por favor, intente de nuevo.`);
      })
      .finally(() => {
        this.loading = false;
      });
    },
    
    handleSearchResults(results) {
      if (!results || results.length === 0) {
        alert('No se encontraron clientes con ese nombre.');
        return;
      }
      
      this.searchResults = results;
      
      // Reset select-related fields
      this.selectedOrganization = '';
      
      // Extract unique organizations
      this.uniqueOrganizations = [...new Set(
        results.filter(r => r.organization).map(r => r.organization)
      )];
      
      if (this.uniqueOrganizations.length > 0) {
        // Show the organization select instead of text input
        this.showOrganizationSelect = true;
        
        // If only one organization, auto-select it
        if (this.uniqueOrganizations.length === 1) {
          this.selectedOrganization = this.uniqueOrganizations[0];
          this.onOrganizationSelected();
        }
      } else {
        alert('No se encontraron organizaciones para este cliente.');
      }
    },
    
    onOrganizationSelected() {
      if (!this.selectedOrganization) return;
      
      // Find the first customer with this organization
      const customer = this.searchResults.find(c => c.organization === this.selectedOrganization);
      
      if (customer) {
        this.fillCustomerData(customer);
      }
    },
    
    fillCustomerData(customer) {
      if (!customer) return;
      
      // Update customer info
      this.form.data.general_info.customer_name = customer.name || this.form.data.general_info.customer_name;
      this.form.data.general_info.customer_organization = customer.organization || this.form.data.general_info.customer_organization;
      this.form.data.general_info.customer_email = customer.email || this.form.data.general_info.customer_email;
      this.form.data.general_info.customer_phone = customer.phone || this.form.data.general_info.customer_phone;
      
      // Update the form
      this.emitFormChanges();
    },
    
    showPipedriveAccountInfo(message, type = 'info') {
      // Create a notification element
      const notificationId = 'pipedrive-account-info-' + Date.now();
      const notification = document.createElement('div');
      notification.id = notificationId;
      notification.className = `alert alert-${type} alert-dismissible fade show mt-2`;
      notification.role = 'alert';
      notification.innerHTML = `
        <strong>Pipedrive Account:</strong> ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      `;
      
      // Find the customer section to add this message
      const customerSection = document.querySelector('#customer-name').closest('.card-body');
      customerSection.appendChild(notification);
      
      // Auto-remove after 10 seconds
      setTimeout(() => {
        const alertElement = document.getElementById(notificationId);
        if (alertElement) {
          alertElement.remove();
        }
      }, 10000);
    }
  }
};
</script>

<style scoped>
.general-tab {
  position: relative;
}

/* Remove the local styles since we're now using global ones in vue_styles.css */
</style> 