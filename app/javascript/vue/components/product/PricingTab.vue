<template>
  <div class="pricing-tab">
    <div class="row">
      <div class="col-md-12">
        <!-- Table section with green accent -->
        <div class="green-accent-panel">
          <!-- Table view for medium and large screens -->
          <div class="d-none d-md-block">
            <table class="table table-dark table-bordered">
              <tbody>
                <tr>
                  <th style="width: 40%">Costo de materiales:</th>
                  <td class="fw-bold text-end">{{ formatCurrency(pricing.materials_cost) }}</td>
                </tr>
                <tr>
                  <th>Costo de procesos:</th>
                  <td class="fw-bold text-end">{{ formatCurrency(pricing.processes_cost) }}</td>
                </tr>
                <tr>
                  <th>Costo de extras:</th>
                  <td class="fw-bold text-end">{{ formatCurrency(pricing.extras_cost) }}</td>
                </tr>
                <tr class="subtotal-row">
                  <th>Subtotal:</th>
                  <td class="text-end">{{ formatCurrency(pricing.subtotal) }}</td>
                </tr>
                <tr>
                  <th class="align-middle">
                    <div class="d-flex justify-content-between align-items-center">
                      <span>Desperdicio:</span>
                      <div class="input-group input-group-sm waste-margin-input">
                        <input 
                          type="number" 
                          class="form-control form-control-sm" 
                          v-model.number="localWastePercentage" 
                          min="0"
                          step="0.1"
                          @change="handleWastePercentageChange"
                          title="Puedes editar este valor manualmente para ajustar el porcentaje de desperdicio"
                          data-toggle="tooltip"
                        />
                        <span class="input-group-text">%</span>
                      </div>
                    </div>
                  </th>
                  <td class="text-end">{{ formatCurrency(pricing.waste_value) }}</td>
                </tr>
                <tr>
                  <th>Precio por pieza (antes del margen):</th>
                  <td class="text-end">{{ formatCurrency(pricing.price_per_piece_before_margin) }}</td>
                </tr>
                <tr>
                  <th class="align-middle">
                    <div class="d-flex justify-content-between align-items-center">
                      <span>Margen:</span>
                      <div class="input-group input-group-sm waste-margin-input">
                        <input 
                          type="number" 
                          class="form-control form-control-sm" 
                          v-model.number="localMarginPercentage" 
                          min="0"
                          step="0.1"
                          @change="handleMarginPercentageChange"
                          title="Puedes editar este valor manualmente para ajustar el porcentaje de margen"
                          data-toggle="tooltip"
                        />
                        <span class="input-group-text">%</span>
                      </div>
                    </div>
                  </th>
                  <td class="text-end">{{ formatCurrency(pricing.margin_value) }}</td>
                </tr>
                <tr class="total-row">
                  <th>Precio total:</th>
                  <td class="fw-bold text-end">{{ formatCurrency(pricing.total_price) }}</td>
                </tr>
                <tr class="total-row">
                  <th>Precio por pieza:</th>
                  <td class="fw-bold text-end">{{ formatCurrency(pricing.final_price_per_piece) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          
          <!-- Card view for small screens -->
          <div class="d-md-none">
            <div class="table-responsive">
              <table class="table table-dark table-bordered mb-0">
                <tbody>
                  <tr>
                    <th style="width: 50%">Costo de materiales:</th>
                    <td class="fw-bold text-end">{{ formatCurrency(pricing.materials_cost) }}</td>
                  </tr>
                  <tr>
                    <th>Costo de procesos:</th>
                    <td class="fw-bold text-end">{{ formatCurrency(pricing.processes_cost) }}</td>
                  </tr>
                  <tr>
                    <th>Costo de extras:</th>
                    <td class="fw-bold text-end">{{ formatCurrency(pricing.extras_cost) }}</td>
                  </tr>
                  <tr class="subtotal-row">
                    <th>Subtotal:</th>
                    <td class="text-end">{{ formatCurrency(pricing.subtotal) }}</td>
                  </tr>
                  <tr>
                    <th class="align-middle">Desperdicio:</th>
                    <td>
                      <div class="d-flex justify-content-end align-items-center">
                        <div class="input-group input-group-sm me-2" style="width: 100px;">
                          <input 
                            type="number" 
                            class="form-control form-control-sm" 
                            v-model.number="localWastePercentage" 
                            min="0"
                            step="0.1"
                            @change="handleWastePercentageChange"
                          />
                          <span class="input-group-text">%</span>
                        </div>
                        <span>{{ formatCurrency(pricing.waste_value) }}</span>
                      </div>
                    </td>
                  </tr>
                  <tr>
                    <th>Precio por pieza (antes del margen):</th>
                    <td class="text-end">{{ formatCurrency(pricing.price_per_piece_before_margin) }}</td>
                  </tr>
                  <tr>
                    <th class="align-middle">Margen:</th>
                    <td>
                      <div class="d-flex justify-content-end align-items-center">
                        <div class="input-group input-group-sm me-2" style="width: 100px;">
                          <input 
                            type="number" 
                            class="form-control form-control-sm" 
                            v-model.number="localMarginPercentage" 
                            min="0"
                            step="0.1"
                            @change="handleMarginPercentageChange"
                          />
                          <span class="input-group-text">%</span>
                        </div>
                        <span>{{ formatCurrency(pricing.margin_value) }}</span>
                      </div>
                    </td>
                  </tr>
                  <tr class="total-row">
                    <th>Precio total:</th>
                    <td class="fw-bold text-end">{{ formatCurrency(pricing.total_price) }}</td>
                  </tr>
                  <tr class="total-row">
                    <th>Precio por pieza:</th>
                    <td class="fw-bold text-end">{{ formatCurrency(pricing.final_price_per_piece) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Buttons section - outside the green accent panel -->
    <div class="d-flex justify-content-end mt-4">
      <a href="/products" class="btn btn-secondary me-2">
        Cancel
      </a>
      <button type="button" class="btn btn-primary" @click="saveProduct" :disabled="saving">
        {{ isNew ? 'Crear producto' : 'Guardar cambios' }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PricingTab',
  props: {
    pricing: {
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
      saving: false,
      localWastePercentage: this.pricing ? (this.pricing.waste_percentage || 0) : 0,
      localMarginPercentage: this.pricing ? (this.pricing.margin_percentage || 0) : 0
    };
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
    },
    saveProduct() {
      // Set saving state
      this.saving = true;
      
      // Just emit the save event directly
      this.$emit('save:product');
    },
    recalculatePricing() {
      console.log('Manually triggering pricing recalculation');
      this.$emit('recalculate:pricing');
    },
    handleWastePercentageChange() {
      // Ensure value is valid
      if (this.localWastePercentage < 0) {
        this.localWastePercentage = 0;
      }
      
      // Create a new pricing object with the updated waste percentage
      const updatedPricing = {
        ...this.pricing,
        waste_percentage: this.localWastePercentage
      };
      
      // Emit an update event instead of directly modifying the prop
      this.$emit('update:pricing', updatedPricing);
      
      // Schedule recalculation for next tick to ensure proper data flow
      this.$nextTick(() => {
        this.recalculatePricing();
      });
    },
    handleMarginPercentageChange() {
      // Ensure value is valid
      if (this.localMarginPercentage < 0) {
        this.localMarginPercentage = 0;
      }
      
      // Create a new pricing object with the updated margin percentage
      const updatedPricing = {
        ...this.pricing,
        margin_percentage: this.localMarginPercentage
      };
      
      // Emit an update event instead of directly modifying the prop
      this.$emit('update:pricing', updatedPricing);
      
      // Schedule recalculation for next tick to ensure proper data flow
      this.$nextTick(() => {
        this.recalculatePricing();
      });
    }
  },
  watch: {
    pricing: {
      handler(newPricing) {
        // Keep local variables in sync with props when external changes occur
        if (newPricing) {
          this.localWastePercentage = newPricing.waste_percentage || 0;
          this.localMarginPercentage = newPricing.margin_percentage || 0;
        }
      },
      deep: true,
      immediate: true
    }
  }
};
</script>

<style scoped>
.pricing-tab {
  position: relative;
}

/* Green accent panel styling */
.green-accent-panel {
  border-left: 4px solid #42b983;
  padding-left: 1rem;
  margin-left: 0.5rem;
}

/* Table styling */
.table {
  color: #e9ecef;
  background-color: #23272b;
  margin-bottom: 0;
}

.table-dark {
  background-color: #23272b;
  color: #e9ecef;
}

.table-dark th {
  background-color: #32383e;
}

.subtotal-row {
  border-top: 2px solid #495057;
}

.total-row {
  background-color: rgba(255, 255, 255, 0.05) !important;
  border-top: 2px solid #495057;
}

.table th,
.table td {
  border-color: #32383e;
  padding: 0.75rem;
  vertical-align: middle;
}

.input-group-sm {
  margin-top: 5px;
}

.input-group-text {
  background-color: #32383e;
  color: #e9ecef;
  border-color: #495057;
}

.form-control-sm {
  background-color: #2c3136;
  color: #e9ecef;
  border-color: #495057;
}

.form-control-sm:focus {
  background-color: #2c3136;
  color: #e9ecef;
  border-color: #42b983;
  box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25);
}

.fw-bold {
  font-weight: bold;
}

.waste-margin-input {
  width: 120px;
  margin-top: 0;
  margin-left: 10px;
}
</style> 