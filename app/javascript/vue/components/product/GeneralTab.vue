<template>
  <div class="general-tab general-info-panel">
    <div class="green-accent-panel">
      <div class="card general-info-card">
        <div class="card-body">
          <form @submit.prevent="saveProduct">
            <div class="row">
              <!-- Left column with form fields -->
              <div class="col-md-8">
                <div class="form-fields-container">
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
                  <div class="mb-3 d-flex gap-3">
                    <div class="flex-grow-1">
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
                    <div class="flex-grow-1">
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
              </div>

              <!-- Right column with comments -->
              <div class="col-md-4">
                <div class="mb-3">
                  <label for="product-comments" class="form-label">Comentarios</label>
                  <textarea 
                    id="product-comments" 
                    class="form-control"
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
import { reactive } from 'vue';

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
      debouncedEmitFormChanges: null,
      styles: null
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
  },
  mounted() {
    // Get the CSS variable value
    const rootStyles = getComputedStyle(document.documentElement);
    const cotaloGreen = rootStyles.getPropertyValue('--cotalo-green').trim();

    console.log('[GeneralTab] Component mounted', {
      version: '2024-04-23-v1',
      hasGreenAccent: !!document.querySelector('.green-accent-panel'),
      componentId: this.$el.id,
      cssVariables: {
        cotaloGreen: cotaloGreen || 'not defined'
      }
    });

    // Log all elements with green-accent-panel class
    document.querySelectorAll('.green-accent-panel').forEach((el, index) => {
      const cardElement = el.querySelector('.card');
      if (!cardElement) {
        console.log(`[GeneralTab] No card element found in panel ${index}`);
        return;
      }

      const computedStyles = window.getComputedStyle(cardElement);
      
      // Extract specific style values
      const styleValues = {
        borderLeft: computedStyles.borderLeft,
        borderLeftWidth: computedStyles.borderLeftWidth,
        borderLeftStyle: computedStyles.borderLeftStyle,
        borderLeftColor: computedStyles.borderLeftColor,
        border: computedStyles.border,
        borderTop: computedStyles.borderTop,
        borderRight: computedStyles.borderRight,
        borderBottom: computedStyles.borderBottom,
        padding: computedStyles.padding,
        paddingLeft: computedStyles.paddingLeft,
        margin: computedStyles.margin,
        marginLeft: computedStyles.marginLeft,
        backgroundColor: computedStyles.backgroundColor
      };

      console.log(`[GeneralTab] Green accent panel ${index} styles:`, 
        JSON.stringify({
          panelType: el.parentElement.className,
          styles: styleValues
        }, null, 2)
      );
    });

    // Log stylesheet information
    const styleSheets = document.styleSheets;
    let greenAccentRules = [];

    Array.from(styleSheets).forEach((sheet, index) => {
      try {
        if (sheet.href === null || sheet.href.includes('GeneralTab')) {
          const rules = Array.from(sheet.cssRules || [])
            .filter(rule => rule.selectorText?.includes('.green-accent-panel'))
            .map(rule => ({
              selector: rule.selectorText,
              css: rule.style.cssText,
              source: sheet.href || 'inline',
              index: index
            }));
          if (rules.length > 0) {
            greenAccentRules.push(...rules);
          }
        }
      } catch (e) {
        console.log(`[GeneralTab] Cannot access rules for stylesheet ${index}:`, sheet.href || 'inline');
      }
    });

    console.log('[GeneralTab] Style information:', JSON.stringify({
      totalStylesheets: styleSheets.length,
      stylesheetSources: Array.from(styleSheets).map(sheet => {
        try {
          return sheet.href || 'inline';
        } catch (e) {
          return 'inaccessible';
        }
      }),
      greenAccentRules: greenAccentRules
    }, null, 2));
  },
  updated() {
    // Component updated
  }
};
</script>

<style lang="scss">
.general-info-panel {
  .green-accent-panel {
    .general-info-card {
      border-top: 1px solid rgb(50, 56, 62) !important;
      border-right: 1px solid rgb(50, 56, 62) !important;
      border-bottom: 1px solid rgb(50, 56, 62) !important;
      border-left: 2px solid var(--cotalo-green, #42b983) !important;
      padding-left: 0.75rem;
      margin-left: 0.5rem;
      background-color: rgb(26, 30, 33);

      .card-body {
        padding: 0;

        form {
          .row {
            margin: 0;
            
            .col-md-8 {
              padding: 1.5rem;
            }

            .col-md-4 {
              padding: 1.5rem;
              border-left: 1px solid rgb(50, 56, 62);
            }
          }
        }
      }
    }
  }
}
</style>