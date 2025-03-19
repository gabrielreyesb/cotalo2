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
                <input 
                  type="text" 
                  id="customer-name" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_name"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-organization" class="form-label">Organización</label>
                <input 
                  type="text" 
                  id="customer-organization" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_organization"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-email" class="form-label">Email</label>
                <input 
                  type="email" 
                  id="customer-email" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_email"
                />
              </div>
              
              <div class="mb-3">
                <label for="customer-phone" class="form-label">Teléfono</label>
                <input 
                  type="tel" 
                  id="customer-phone" 
                  class="form-control" 
                  v-model="form.data.general_info.customer_phone"
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
              rows="3"
            ></textarea>
          </div>
        </div>
      </div>
      
      <div class="d-flex justify-content-end mt-4">
        <a href="/products" class="btn btn-secondary me-2">
          Cancel
        </a>
        <button type="submit" class="btn btn-primary" :disabled="saving">
          {{ isNew ? 'Crear producto' : 'Guardar cambios' }}
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
      console.log('Initializing form data with product:', this.product);
      
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
      
      console.log('Form initialized with data:', this.form);
    },
    saveProduct() {
      this.saving = true;
      
      console.log('Saving product with form data:', this.form);
      
      // Create a copy for the update, ensuring we have a valid data structure
      const updatedProduct = {
        description: this.form.description,
        data: {
          ...(this.product && this.product.data ? this.product.data : {}),
          general_info: { ...this.form.data.general_info }
        }
      };
      
      console.log('Emitting product update with:', updatedProduct);
      
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