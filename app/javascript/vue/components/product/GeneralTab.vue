<template>
  <div class="general-tab">
    <form @submit.prevent="saveProduct">
      <div class="row">
        <div class="col-md-6">
          <div class="card mb-3">
            <div class="card-body">
              <div class="card-title">Product Details</div>
              
              <div class="mb-3">
                <label for="product-description" class="form-label">Product Description</label>
                <input 
                  type="text" 
                  id="product-description" 
                  class="form-control" 
                  v-model="form.description" 
                  required
                  placeholder="Enter product description"
                />
              </div>
              
              <div class="mb-3">
                <label for="product-quantity" class="form-label">Quantity</label>
                <input 
                  type="number" 
                  id="product-quantity" 
                  class="form-control" 
                  v-model.number="form.data.general_info.quantity" 
                  min="1" 
                  required
                  placeholder="Enter quantity"
                />
              </div>
              
              <div class="row">
                <div class="col-md-6">
                  <div class="mb-3">
                    <label for="product-width" class="form-label">Width (cm)</label>
                    <input 
                      type="number" 
                      id="product-width" 
                      class="form-control" 
                      v-model.number="form.data.general_info.width" 
                      min="0" 
                      step="0.1"
                      placeholder="Enter width"
                    />
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="mb-3">
                    <label for="product-length" class="form-label">Length (cm)</label>
                    <input 
                      type="number" 
                      id="product-length" 
                      class="form-control" 
                      v-model.number="form.data.general_info.length" 
                      min="0" 
                      step="0.1"
                      placeholder="Enter length"
                    />
                  </div>
                </div>
              </div>
              
              <div class="mb-3">
                <label for="product-inner-measurements" class="form-label">Inner Measurements</label>
                <input 
                  type="text" 
                  id="product-inner-measurements" 
                  class="form-control" 
                  v-model="form.data.general_info.inner_measurements"
                  placeholder="Enter inner measurements"
                />
              </div>
            </div>
          </div>
        </div>
        
        <div class="col-md-6">
          <div class="card mb-3">
            <div class="card-body">
              <div class="card-title">Customer Information</div>
              
              <div class="mb-3">
                <label for="customer-name" class="form-label">Customer Name</label>
                <input 
                  type="text" 
                  id="customer-name" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_name"
                  placeholder="Enter customer name"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-organization" class="form-label">Organization</label>
                <input 
                  type="text" 
                  id="customer-organization" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_organization"
                  placeholder="Enter organization"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-email" class="form-label">Email</label>
                <input 
                  type="email" 
                  id="customer-email" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_email"
                  placeholder="Enter email"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-phone" class="form-label">Phone</label>
                <input 
                  type="tel" 
                  id="customer-phone" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_phone"
                  placeholder="Enter phone number"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="card mb-3">
        <div class="card-body">
          <div class="card-title">Additional Information</div>
          
          <div class="mb-3">
            <label for="product-comments" class="form-label">Comments</label>
            <textarea 
              id="product-comments" 
              class="form-control" 
              v-model="form.data.general_info.comments" 
              rows="3"
              placeholder="Enter any additional comments"
            ></textarea>
          </div>
        </div>
      </div>
      
      <div class="d-flex justify-content-end mt-4">
        <a href="/products" class="btn btn-secondary me-2">
          Cancel
        </a>
        <button type="submit" class="btn btn-primary" :disabled="saving">
          {{ isNew ? 'Create Product' : 'Save Changes' }}
        </button>
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
      saving: false
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
      // Create deep copy to avoid modifying props directly
      this.form = {
        description: this.product.description || '',
        data: {
          general_info: { ...this.product.data?.general_info || {} }
        }
      };
      
      // Ensure minimum value for quantity
      if (!this.form.data.general_info.quantity || this.form.data.general_info.quantity < 1) {
        this.form.data.general_info.quantity = 1;
      }
      
      console.log('Form initialized with data:', this.form);
    },
    saveProduct() {
      this.saving = true;
      
      // Create a copy for the update
      const updatedProduct = {
        description: this.form.description,
        data: { ...this.product.data }
      };
      
      // Update only the general_info part
      updatedProduct.data.general_info = { ...this.form.data.general_info };
      
      // Emit the appropriate event based on whether this is a new product or an existing one
      if (this.isNew) {
        this.$emit('create:product', updatedProduct);
      } else {
        this.$emit('update:product', updatedProduct);
      }
      
      this.saving = false;
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