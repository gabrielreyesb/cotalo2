<template>
  <div class="extras-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-7 mb-3 mb-md-0 me-md-2">
              <div class="d-flex align-items-center mb-2">
                <label for="extra-select" class="form-label mb-0 me-2">{{ translations.extras_tab.select_extra }}</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  :title="translations.extras_tab.indirect_costs_tooltip || '¿Qué son los costos indirectos?<br>Son costos adicionales que no dependen directamente de los materiales o procesos, pero que son necesarios para producir el producto.<br>Incluyen cosas como la fabricación de troqueles, placas offset, calibraciones o desarrollo de muestras físicas.'"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
              <multiselect
                v-model="selectedExtraId"
                :options="availableExtras"
                :track-by="'id'"
                :label="'name'"
                :placeholder="''"
                :disabled="!availableExtras.length"
                :select-label="''"
                @select="onExtraSelect"
              />
            </div>
            <div class="col-md-2 mb-3 mb-md-0 me-md-2">
              <label for="extra-quantity" class="form-label">{{ translations.extras_tab.quantity }}</label>
              <input 
                id="extra-quantity" 
                type="number" 
                v-model.number="quantity" 
                class="form-control border-secondary text-end" 
                style="color-scheme: dark;"
                min="1" 
                step="1"
                :disabled="!selectedExtraId"
              />
            </div>
            <div class="col-md-2 d-grid align-items-end">
              <button 
                class="btn btn-primary w-100" 
                @click="addExtra" 
                :disabled="!canAdd"
              >
                <i class="fa fa-plus me-1"></i> {{ translations.extras_tab.add_extra }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="!productExtras.length" class="text-center my-5">
      <p class="text-muted">{{ translations.extras_tab.no_extras }}</p>
    </div>

    <!-- Table view for medium and large screens -->
    <div class="green-accent-panel mt-4" v-if="productExtras.length">
      <div class="card">
        <div class="card-body p-0">
          <!-- Desktop: Include in subtotal checkbox -->
          <div class="form-check px-4 py-3 border-bottom border-secondary extras-checkbox-padding d-none d-md-block">
            <input 
              class="form-check-input" 
              type="checkbox" 
              id="include-extras-subtotal" 
              v-model="includeInSubtotal"
              @change="updateIncludeInSubtotal"
            >
            <label class="form-check-label ms-2" for="include-extras-subtotal">
              {{ translations.extras_tab.include_in_subtotal }}
            </label>
          </div>

          <!-- Mobile: Include in subtotal checkbox -->
          <div class="form-check px-4 py-3 border-bottom border-secondary d-md-none">
            <input 
              class="form-check-input" 
              type="checkbox" 
              id="include-extras-subtotal-mobile" 
              v-model="includeInSubtotal"
              @change="updateIncludeInSubtotal"
            >
            <label class="form-check-label ms-2" for="include-extras-subtotal-mobile">
              {{ translations.extras_tab.include_in_subtotal_mobile }}
            </label>
          </div>

          <!-- Desktop Table -->
          <div class="d-none d-md-block">
            <table class="table table-striped mb-0">
              <thead>
                <tr>
                  <th style="width: 20%">{{ translations.extras_tab.table.name }}</th>
                  <th style="width: 35%">{{ translations.extras_tab.table.description }}</th>
                  <th class="text-end" style="width: 15%">{{ translations.extras_tab.table.unit_price }}</th>
                  <th class="text-end" style="width: 15%">{{ translations.extras_tab.table.quantity }}</th>
                  <th class="text-end" style="width: 15%">{{ translations.extras_tab.table.total }}</th>
                  <th class="text-center" style="width: 8%">{{ translations.extras_tab.table.actions }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(extra, index) in productExtras" :key="index">
                  <td class="text-truncate" style="max-width: 140px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="extra.name">{{ extra.name }}</td>
                  <td class="text-truncate" style="max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="extra.description">{{ extra.description }}</td>
                  <td class="text-end">
                    <input
                      type="text"
                      class="form-control form-control-sm text-end border-secondary"
                      :value="extra._unit_price_edit"
                      @input="e => onUnitPriceInput(index, e.target.value)"
                      @blur="() => onUnitPriceBlur(index)"
                      min="0"
                      step="0.01"
                      :title="translations.extras_tab.tooltips.edit_price"
                      data-toggle="tooltip"
                    >
                  </td>
                  <td class="text-end">
                    <div class="input-group input-group-sm">
                      <input 
                        type="number" 
                        class="form-control form-control-sm text-end border-secondary"
                        v-model.number="extra.quantity"
                        min="1"
                        @change="updateExtraQuantity(index)"
                        :title="translations.extras_tab.tooltips.edit_quantity"
                        data-toggle="tooltip"
                      >
                    </div>
                  </td>
                  <td class="text-end">{{ formatCurrency(calculateExtraTotal(extra)) }}</td>
                  <td class="text-center">
                    <div class="btn-group">
                      <button 
                        class="btn btn-sm btn-outline-danger" 
                        @click="removeExtra(index)"
                        :title="translations.extras_tab.tooltips.remove_extra"
                      >
                        <i class="fa fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <th colspan="4" class="text-end">{{ translations.extras_tab.total_extras }}</th>
                  <th class="text-end">{{ formatCurrency(totalCost) }}</th>
                  <th></th>
                </tr>
              </tfoot>
            </table>
          </div>

          <!-- Mobile Cards -->
          <div class="d-md-none">
            <div v-for="(extra, index) in productExtras" :key="index" class="card mb-3 shadow-sm mx-2 mt-3">
              <div class="card-body p-2">
                <!-- Extra name -->
                <h6 class="card-title mb-2"><i class="fa fa-cube me-1"></i>{{ extra.name }}</h6>
                <!-- Icon-value-unit grid -->
                <div class="row g-2 mb-2 text-center">
                  <div class="col-6 d-flex flex-column align-items-center">
                    <span><i class="fa fa-dollar-sign me-1"></i>
                      <input 
                        type="text" 
                        class="form-control form-control-sm text-center p-2 w-100 editable-badge d-inline-block"
                        :value="extra._unit_price_edit"
                        @input="e => onUnitPriceInput(index, e.target.value)"
                        @blur="() => onUnitPriceBlur(index)"
                        min="0"
                        step="0.01"
                        :title="translations.extras_tab.tooltips.edit_price"
                        style="max-width: 70px; display: inline-block;"
                      /> <span class="text-muted">$</span>
                    </span>
                  </div>
                  <div class="col-6 d-flex flex-column align-items-center">
                    <span><i class="fa fa-hashtag me-1"></i>
                      <input 
                        type="number" 
                        class="form-control form-control-sm text-center p-2 w-100 editable-badge d-inline-block"
                        v-model.number="extra.quantity"
                        min="1"
                        @change="updateExtraQuantity(index)"
                        :title="translations.extras_tab.tooltips.edit_quantity"
                        style="max-width: 70px; display: inline-block;"
                      /> <span class="text-muted">x</span>
                    </span>
                  </div>
                </div>
                <div class="row g-2 mb-2 text-center">
                  <div class="col-6 d-flex flex-column align-items-center">
                    <span><i class="fa fa-calculator me-1"></i>
                      <span class="fw-bold">{{ formatCurrency(calculateExtraTotal(extra)) }}</span> <span class="text-muted">$</span>
                    </span>
                  </div>
                  <div class="col-6 d-flex flex-column align-items-center">
                    <button 
                      class="btn btn-sm btn-outline-danger" 
                      @click="removeExtra(index)"
                      :title="translations.extras_tab.tooltips.remove_extra"
                    >
                      <i class="fa fa-trash"></i>
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <!-- Total cost for small screens -->
            <div class="card bg-dark text-white mx-2 mb-3">
              <div class="card-body py-2">
                <div class="d-flex justify-content-between align-items-center">
                  <span class="fw-bold">{{ translations.extras_tab.total_extras }}</span>
                  <span class="fs-5">{{ formatCurrency(totalCost) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Global comments for all extras -->
    <div class="green-accent-panel mt-3 mb-4">
      <div class="card">
        <div class="card-body">
          <div class="form-group">
            <label for="global-comments" class="form-label">{{ translations.extras_tab.comments_label }}</label>
            <textarea 
              id="global-comments" 
              class="form-control border-secondary" 
              v-model="globalComments" 
              rows="3"
              :placeholder="''"
              @change="updateGlobalComments"
            ></textarea>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import Multiselect from 'vue-multiselect'
import 'vue-multiselect/dist/vue-multiselect.min.css'

export default {
  name: 'ExtrasTab',
  components: {
    Multiselect,
  },
  props: {
    productExtras: {
      type: Array,
      default: () => []
    },
    availableExtras: {
      type: Array,
      default: () => []
    },
    comments: {
      type: String,
      default: ''
    },
    productQuantity: {
      type: Number,
      default: 1
    },
    includeExtrasInSubtotal: {
      type: Boolean,
      default: true
    },
    translations: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      selectedExtraId: null,
      quantity: 1,
      globalComments: this.comments || '',
      includeInSubtotal: this.includeExtrasInSubtotal
    }
  },
  computed: {
    canAdd() {
      return this.selectedExtraId && this.quantity > 0;
    },
    selectedExtra() {
      return this.selectedExtraId;
    },
    totalCost() {
      return this.productExtras.reduce((sum, extra) => sum + extra.total, 0);
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value);
    },
    calculateExtraTotal(extra) {
      return extra.total;
    },
    updateExtraQuantity(index) {
      const extra = this.productExtras[index];
      if (extra.quantity < 1) {
        extra.quantity = 1;
      }
      extra.total = extra.unit_price * extra.quantity;
      this.$emit('update:product-extras', this.productExtras);
      this.$emit('update:extras-cost', this.totalCost);
    },
    updateExtraPrice(index) {
      const extra = this.productExtras[index];
      if (extra.unit_price < 0) {
        extra.unit_price = 0;
      }
      extra.total = extra.unit_price * extra.quantity;
      this.$emit('update:product-extras', this.productExtras);
      this.$emit('update:extras-cost', this.totalCost);
    },
    addExtra() {
      if (!this.selectedExtraId) {
        window.showWarning(this.translations.extras_tab.select_extra || 'Por favor, selecciona un extra');
        return;
      }
      if (!this.quantity || this.quantity <= 0) {
        window.showWarning('Por favor, especifica una cantidad válida');
        return;
      }
      if (!this.canAdd || !this.selectedExtra) {
        window.showWarning('No se puede agregar el extra. Verifica que todos los campos requeridos estén completos.');
        return;
      }
      
      const newExtra = {
        id: this.selectedExtra.id,
        name: this.selectedExtra.name,
        description: this.selectedExtra.description,
        unit_price: this.selectedExtra.unit_price,
        unit: this.selectedExtra.unit,
        quantity: this.quantity,
        total: this.selectedExtra.unit_price * this.quantity,
        comments: '',
        _unit_price_edit: Number(this.selectedExtra.unit_price).toFixed(2)
      };
      const updatedExtras = [...this.productExtras, newExtra];
      this.$emit('update:product-extras', updatedExtras);
      this.$emit('update:extras-cost', this.totalCost);
      
      this.selectedExtraId = null;
      this.quantity = 1;
    },
    removeExtra(index) {
      const extraToRemove = this.productExtras[index];
      const updatedExtras = [...this.productExtras];
      updatedExtras.splice(index, 1);
      this.$emit('update:product-extras', updatedExtras);
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    },
    updateExtrasCalculations() {      
      // For now, just emit the current extras to ensure pricing gets updated
      this.$emit('update:product-extras', [...this.productExtras]);
    },
    updateIncludeInSubtotal() {
      this.$emit('update:include-extras-in-subtotal', this.includeInSubtotal);
    },
    onExtraSelect(selectedOption) {
      if (!selectedOption) {
        return;
      }

      // Check if the extra is already added
      if (this.productExtras.some(extra => extra.id === selectedOption.id)) {
        window.showWarning('Este extra ya ha sido agregado. Selecciona otro extra o modifica la cantidad del existente.');
        return;
      }
    },
    onUnitPriceInput(index, value) {
      this.productExtras[index]._unit_price_edit = value;
    },
    onUnitPriceBlur(index) {
      let value = this.productExtras[index]._unit_price_edit;
      let parsed = parseFloat(value.replace(/[^0-9.]/g, ''));
      if (isNaN(parsed)) parsed = 0;
      this.productExtras[index]._unit_price_edit = parsed.toFixed(2);
      this.productExtras[index].unit_price = parsed;
      this.updateExtraPrice(index);
    },
    initializeTooltips() {
      // Dispose existing tooltips first
      this.disposeTooltips();
      
      // Initialize new tooltips
      const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
      tooltipTriggerList.forEach(tooltipTriggerEl => {
        new bootstrap.Tooltip(tooltipTriggerEl, {
          html: true,
          placement: tooltipTriggerEl.dataset.bsPlacement || 'bottom'
        });
      });
    },
    disposeTooltips() {
      const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
      tooltips.forEach(element => {
        const tooltip = bootstrap.Tooltip.getInstance(element);
        if (tooltip) {
          tooltip.dispose();
        }
      });
    },
    handleLanguageChange() {
      // Reinitialize tooltips when language changes
      this.$nextTick(() => {
        this.initializeTooltips();
      });
    }
  },
  watch: {
    // Watch for changes to product quantity
    productQuantity() {
      this.updateExtrasCalculations();
    },
    productExtras: {
      handler(newVal) {
        newVal.forEach(extra => {
          if (typeof extra._unit_price_edit === 'undefined') {
            extra._unit_price_edit = extra.unit_price != null ? Number(extra.unit_price).toFixed(2) : '';
          }
        });
        // Reinitialize tooltips when extras change
        this.$nextTick(() => {
          this.initializeTooltips();
        });
      },
      deep: true,
      immediate: true
    }
  },
  mounted() {
    // Need to import Bootstrap Modal JS
    import('bootstrap/js/dist/modal');
    
    // Initialize tooltips
    this.initializeTooltips();

    // Listen for language changes
    window.addEventListener('languageChanged', this.handleLanguageChange);
    
    // Only emit initial extras cost if there are actual extras
    if (this.productExtras.length > 0) {
      const initialCost = this.productExtras.reduce((sum, extra) => sum + (parseFloat(extra.total) || 0), 0);
      this.$emit('update:extras-cost', initialCost);
    }

    // Initialize _unit_price_edit for each extra
    this.productExtras.forEach(extra => {
      extra._unit_price_edit = extra.unit_price != null ? Number(extra.unit_price).toFixed(2) : '';
    });
  },
  beforeUnmount() {
    // Clean up event listener
    window.removeEventListener('languageChanged', this.handleLanguageChange);
    
    // Clean up tooltips
    this.disposeTooltips();
  }
}
</script>

<style scoped>
.extras-checkbox-padding {
  padding-top: 1.25rem !important;
  padding-bottom: 1.25rem !important;
  padding-left: 1.5rem !important;
  padding-right: 1.5rem !important;
}
.extras-checkbox-padding .form-check-input {
  margin-left: 0.5rem;
  margin-right: 1rem;
}
</style>