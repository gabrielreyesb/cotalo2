<template>
  <div class="extras-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-7 mb-3 mb-md-0 me-md-2">
              <div class="d-flex align-items-center mb-2">
                <label for="extra-select" class="form-label mb-0 me-2">{{ translations.extras_tab.select_extra }}</label>
              </div>
              <multiselect
                v-model="selectedExtraId"
                :options="availableExtras"
                :track-by="'id'"
                :label="'name'"
                :placeholder="''"
                :disabled="!availableExtras.length"
                :select-label="translations.extras_tab.press_enter_to_select"
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
          <div class="form-check px-4 py-3 border-bottom border-secondary extras-checkbox-padding">
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
            <div class="form-check px-4 py-3 border-bottom border-secondary">
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
            <div v-for="(extra, index) in productExtras" :key="index" class="card mb-3 shadow-sm mx-2 mt-3">
              <div class="card-body p-2">
                <!-- First row: Extra name and description -->
                <h6 class="card-title mb-2">{{ extra.name }}</h6>
                <p class="text-muted small mb-2">{{ extra.description }}</p>
                
                <!-- Second row: Price and quantity -->
                <div class="row g-2 mb-2">
                  <div class="col-6">
                    <div class="input-group input-group-sm">
                      <input 
                        type="text" 
                        class="form-control form-control-sm text-end border-secondary"
                        :value="extra._unit_price_edit"
                        @input="e => onUnitPriceInput(index, e.target.value)"
                        @blur="() => onUnitPriceBlur(index)"
                        min="0"
                        step="0.01"
                        :title="translations.extras_tab.tooltips.edit_price"
                      />
                      <span class="input-group-text">$</span>
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="input-group input-group-sm">
                      <input 
                        type="number" 
                        class="form-control form-control-sm text-end border-secondary"
                        v-model.number="extra.quantity"
                        min="1"
                        @change="updateExtraQuantity(index)"
                        :title="translations.extras_tab.tooltips.edit_quantity"
                      />
                    </div>
                  </div>
                </div>
                
                <!-- Third row: Total price and delete button -->
                <div class="d-flex justify-content-between align-items-center">
                  <span class="badge bg-success fs-5">{{ formatCurrency(calculateExtraTotal(extra)) }}</span>
                  <button 
                    class="btn btn-sm btn-outline-danger px-2 py-1" 
                    @click="removeExtra(index)"
                    :title="translations.extras_tab.tooltips.remove_extra"
                  >
                    <i class="fa fa-trash fa-sm"></i>
                  </button>
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
      
      // Show info notification for quantity update
      window.showInfo(`Cantidad del extra "${extra.name}" actualizada`);
    },
    updateExtraPrice(index) {
      const extra = this.productExtras[index];
      if (extra.unit_price < 0) {
        extra.unit_price = 0;
      }
      extra.total = extra.unit_price * extra.quantity;
      this.$emit('update:product-extras', this.productExtras);
      this.$emit('update:extras-cost', this.totalCost);
      
      // Show info notification for price update
      window.showInfo(`Precio del extra "${extra.name}" actualizado`);
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
      
      // Show success notification
      window.showSuccess(`Extra "${extraToRemove.name}" eliminado exitosamente`);
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
      
      // Show info notification for comments update
      window.showInfo('Comentarios de extras actualizados');
    },
    updateExtrasCalculations() {      
      // For now, just emit the current extras to ensure pricing gets updated
      this.$emit('update:product-extras', [...this.productExtras]);
    },
    updateIncludeInSubtotal() {
      this.$emit('update:include-extras-in-subtotal', this.includeInSubtotal);
      
      // Show info notification for subtotal setting update
      const message = this.includeInSubtotal 
        ? 'Extras incluidos en el subtotal' 
        : 'Extras excluidos del subtotal';
      window.showInfo(message);
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
      },
      deep: true,
      immediate: true
    }
  },
  mounted() {
    // Need to import Bootstrap Modal JS
    import('bootstrap/js/dist/modal');
    
    // Emit initial extras cost when component mounts
    const initialCost = this.productExtras.reduce((sum, extra) => sum + (parseFloat(extra.total) || 0), 0);
    this.$emit('update:extras-cost', initialCost);
    
    // Show info notification if there are existing extras
    if (this.productExtras.length > 0) {
      window.showInfo(`${this.productExtras.length} extra(s) cargado(s) - Total: ${this.formatCurrency(initialCost)}`);
    }

    // Initialize _unit_price_edit for each extra
    this.productExtras.forEach(extra => {
      extra._unit_price_edit = extra.unit_price != null ? Number(extra.unit_price).toFixed(2) : '';
    });
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