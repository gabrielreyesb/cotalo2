<template>
  <div class="general-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <form @submit.prevent="saveProduct">
            <div class="row">
              <!-- Left column with form fields -->
              <div class="col-md-8">
                <!-- Product Description -->
                <div class="mb-3">
                  <label for="product-description" class="form-label">Descripción del producto</label>
                  <input 
                    type="text" 
                    id="product-description" 
                    class="form-control" 
                    v-model="form.description" 
                    @input="debouncedEmitFormChanges"
                    required
                  />
                </div>

                <!-- Quantity -->
                <div class="mb-3">
                  <label for="product-quantity" class="form-label">Cantidad de piezas</label>
                  <input 
                    type="number" 
                    id="product-quantity" 
                    class="form-control" 
                    :value="form.data.general_info.quantity" 
                    @input="handleQuantityInput"
                    min="1" 
                    required
                  />
                </div>

                <!-- Width and Length -->
                <div class="row">
                  <div class="col-md-6">
                    <div class="mb-3">
                      <label for="product-width" class="form-label">Ancho (cm)</label>
                      <input 
                        type="number" 
                        id="product-width" 
                        class="form-control" 
                        :value="form.data.general_info.width" 
                        @input="handleWidthInput"
                        min="0" 
                        step="0.1"
                        required
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
                        :value="form.data.general_info.length" 
                        @input="handleLengthInput"
                        min="0" 
                        step="0.1"
                        required
                      />
                    </div>
                  </div>
                </div>

                <!-- Internal Measurements -->
                <div class="mb-3">
                  <label for="product-inner-measurements" class="form-label">Medidas internas</label>
                  <input 
                    type="text" 
                    id="product-inner-measurements" 
                    class="form-control" 
                    v-model="form.data.general_info.inner_measurements" 
                    @input="debouncedEmitFormChanges"
                  />
                </div>
              </div>

              <!-- Right column with comments -->
              <div class="col-md-4">
                <div class="mb-3">
                  <label for="product-comments" class="form-label">Comentarios</label>
                  <textarea 
                    id="product-comments" 
                    class="form-control"
                    style="min-height: 295px; height: calc(100% - 24px); resize: none;"
                    v-model="form.data.general_info.comments" 
                    @input="debouncedEmitFormChanges"
                  ></textarea>
                </div>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
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
            quantity: null,
            comments: ''
          }
        }
      },
      saving: false,
      debouncedEmitFormChanges: null
    };
  },
  created() {
    // Initialize form data when component is created
    if (this.product) {
      this.initFormData();
    }
    // Create a debounced version of emitFormChanges
    this.debouncedEmitFormChanges = this.debounce(() => {
      this.emitFormChanges();
    }, 500);
  },
  methods: {
    debounce(func, wait) {
      let timeout;
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout);
          func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
      };
    },
    initFormData() {
      // Default empty structure in case product data is incomplete
      const defaultGeneralInfo = {
        width: null,
        length: null,
        inner_measurements: '',
        quantity: null,
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
    },
    emitFormChanges() {
      this.$emit('update:product', {
        description: this.form.description,
        data: {
          general_info: this.form.data.general_info
        }
      });
    },
    
    handleQuantityInput(event) {
      this.form.data.general_info.quantity = event.target.value === '' ? null : parseInt(event.target.value);
      this.debouncedEmitFormChanges();
    },
    handleWidthInput(event) {
      // Update local state directly from input value
      this.form.data.general_info.width = event.target.value === '' ? null : parseFloat(event.target.value);
      // Trigger the debounced emit
      this.debouncedEmitFormChanges();
    },
    handleLengthInput(event) {
      this.form.data.general_info.length = event.target.value === '' ? null : parseFloat(event.target.value);
      this.debouncedEmitFormChanges();
    },
    async saveProduct() {
      this.saving = true;
      
      try {
        if (this.isNew) {
          this.$emit('create:product', {
            description: this.form.description,
            data: {
              general_info: this.form.data.general_info
            }
          });
        } else {
          this.$emit('update:product', {
            description: this.form.description,
            data: {
              general_info: this.form.data.general_info,
              shouldRedirect: true
            }
          });
        }
      } catch (error) {
        console.error('Error saving product:', error);
      } finally {
        this.saving = false;
      }
    }
  }
};
</script>

<style scoped>
.h-100 {
  height: 100%;
}
</style>