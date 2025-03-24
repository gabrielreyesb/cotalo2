<template>
  <div class="pricing-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <table class="table table-dark">
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
    
    <div class="d-flex justify-content-end gap-2 mt-4">
      <button type="button" class="btn btn-secondary" @click="$emit('cancel')">Cancel</button>
      <button type="button" class="btn btn-primary" @click="saveProduct">Crear producto</button>
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

/* Table styling */
.table {
  color: #e9ecef;
  background-color: #23272b;
  margin-bottom: 0;
}

.table th,
.table td {
  border-color: #32383e;
  padding: 0.75rem;
  vertical-align: middle;
}

.subtotal-row,
.total-row {
  border-top: 2px solid #495057;
}

.total-row {
  background-color: rgba(255, 255, 255, 0.05);
}

/* Form controls */
.form-control {
  color: #e1e1e1;
  background-color: #2c3136;
  border: 1px solid #495057;
  border-radius: 4px;
}

.form-control:focus {
  border-color: #42b983;
  background-color: #2c3136;
  color: #e1e1e1;
  box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25);
}

.input-group-text {
  background-color: #32383e;
  color: #e9ecef;
  border-color: #495057;
}

/* Button styling */
.btn-primary {
  color: #fff;
  background-color: #42b983;
  border-color: #42b983;
}

.btn-primary:hover {
  background-color: #3aa876;
  border-color: #3aa876;
}

.btn-secondary {
  color: #adb5bd;
  border-color: #495057;
}

.btn-secondary:hover {
  background-color: #495057;
  color: #fff;
}
</style> 