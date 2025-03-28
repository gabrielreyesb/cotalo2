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
      <button type="button" class="btn btn-secondary" @click="$emit('cancel')">Cancelar</button>
      <button type="button" class="btn btn-primary" @click="saveProduct">
        {{ isNew ? 'Crear producto' : 'Actualizar producto' }}
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