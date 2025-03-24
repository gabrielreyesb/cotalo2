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

/* Remove the local styles since we're now using global ones in vue_styles.css */
</style> 