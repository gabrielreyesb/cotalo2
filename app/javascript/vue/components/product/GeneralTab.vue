<template>
  <div class="general-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <form @submit.prevent="saveProduct">
            <div class="row">
              <div class="col-md-6">
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
              
              <div class="col-md-6">
                <div class="mb-3">
                  <label for="product-comments" class="form-label">Comentarios</label>
                  <textarea 
                    id="product-comments" 
                    class="form-control" 
                    v-model="form.data.general_info.comments" 
                    @input="emitFormChanges"
                    rows="11"
                    style="height: 100%; min-height: 300px;"
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
              general_info: this.form.data.general_info
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
.general-tab {
  position: relative;
}

/* Green accent panel styling - Base */
.green-accent-panel > .card:not(.shadow-sm) {
  border-left: 4px solid #42b983;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
}

/* Table styling with green accent */
.green-accent-panel > table.table {
  border-left: 4px solid #42b983;
  margin-left: 0.5rem;
}

/* Add green line only to direct container divs */
.green-accent-panel > div.d-none,
.green-accent-panel > div.d-md-none {
  border-left: 4px solid #42b983;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
}

/* No content message styling */
.green-accent-panel > .text-center {
  border-left: 4px solid #42b983;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
}

/* Card styling for content within responsive containers - no border */
.green-accent-panel > div > .card.shadow-sm {
  border-left: none;
  padding-left: 0;
  margin-left: 0;
}

/* Card styling */
.card {
  background-color: #23272b;
  border-color: #32383e;
  margin-bottom: 1.5rem;
  box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.15);
}

.card-body {
  padding: 1rem;
}

/* Form controls with green focus */
.form-select, 
.form-control {
  color: #e1e1e1;
  background-color: #2c3136;
  border: 1px solid #495057;
  border-radius: 4px;
}

.form-select:focus,
.form-control:focus {
  border-color: #42b983;
  background-color: #2c3136;
  color: #e1e1e1;
  box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25);
}

.form-select::placeholder,
.form-control::placeholder {
  color: #6c757d;
}

/* Label styling */
.form-label {
  color: #adb5bd;
  margin-bottom: 0.5rem;
}
</style> 