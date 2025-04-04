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
                    @input="debouncedEmitFormChanges"
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
                    @input="debouncedEmitFormChanges"
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
                        @input="debouncedEmitFormChanges"
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
                        @input="debouncedEmitFormChanges"
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
                    @input="debouncedEmitFormChanges"
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
                    @input="debouncedEmitFormChanges"
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
      saving: false,
      debouncedEmitFormChanges: null
    };
  },
  created() {
    // Create a debounced version of emitFormChanges
    this.debouncedEmitFormChanges = this.debounce(() => {
      this.emitFormChanges();
    }, 500);
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