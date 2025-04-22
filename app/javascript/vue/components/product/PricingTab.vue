<template>
  <div class="pricing-tab">
    <table class="table table-dark mb-0">
      <tbody>
        <tr>
          <th style="width: 50%">Costo de materiales:</th>
          <td class="text-end">{{ formatCurrency(pricing.materials_cost) }}</td>
        </tr>
        <tr>
          <th>Costo de procesos:</th>
          <td class="text-end">{{ formatCurrency(pricing.processes_cost) }}</td>
        </tr>
        <tr :class="{ 'bg-danger bg-opacity-10': pricing.extras_cost > 0 && pricing.include_extras_in_subtotal === false }">
          <th>Costo de extras:</th>
          <td class="text-end">{{ formatCurrency(pricing.extras_cost) }}</td>
        </tr>
        <tr class="subtotal-row">
          <th>Subtotal:</th>
          <td class="text-end">{{ formatCurrency(pricing.subtotal) }}</td>
        </tr>
        <tr>
          <th class="align-middle">Desperdicio:</th>
          <td>
            <div class="d-flex justify-content-end align-items-center gap-2">
              <div class="input-group input-group-sm" style="width: 100px;">
                <input 
                  type="number" 
                  class="form-control form-control-sm text-end" 
                  v-model.number="localWastePercentage" 
                  min="0"
                  step="0.1"
                  @change="handleWastePercentageChange"
                />
                <span class="input-group-text">%</span>
              </div>
              <span class="value-display">{{ formatCurrency(pricing.waste_value) }}</span>
            </div>
          </td>
        </tr>
        <tr class="subtotal-with-waste-row">
          <th>Subtotal con desperdicio:</th>
          <td class="text-end">{{ formatCurrency(pricing.subtotal + pricing.waste_value) }}</td>
        </tr>
        <tr>
          <th class="align-middle">Margen:</th>
          <td>
            <div class="d-flex justify-content-end align-items-center gap-2">
              <div class="input-group input-group-sm" style="width: 100px;">
                <input 
                  type="number" 
                  class="form-control form-control-sm text-end" 
                  v-model.number="localMarginPercentage" 
                  min="0"
                  step="0.1"
                  @change="handleMarginPercentageChange"
                />
                <span class="input-group-text">%</span>
              </div>
              <span class="value-display">{{ formatCurrency(pricing.margin_value) }}</span>
            </div>
          </td>
        </tr>
        <tr class="total-row">
          <th>Precio total:</th>
          <td class="text-end">{{ formatCurrency(pricing.total_price) }}</td>
        </tr>
        <tr class="final-price-row">
          <th>Precio por pieza:</th>
          <td class="text-end">{{ formatCurrency(pricing.final_price_per_piece) }}</td>
        </tr>
      </tbody>
    </table>
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
    },
    suggestedMargin: {
      type: Number,
      default: 0
    }
  },
  data() {
    return {
      localWastePercentage: this.pricing.waste_percentage || 5,
      localMarginPercentage: this.pricing.margin_percentage || 0
    };
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
      }).format(value);
    },
    handleWastePercentageChange() {
      this.$emit('update:pricing', {
        ...this.pricing,
        waste_percentage: this.localWastePercentage
      });
      this.$emit('recalculate:pricing');
    },
    handleMarginPercentageChange() {
      this.$emit('update:pricing', {
        ...this.pricing,
        margin_percentage: this.localMarginPercentage
      });
      this.$emit('recalculate:pricing');
    }
  },
  watch: {
    'pricing.waste_percentage': {
      handler(newVal) {
        this.localWastePercentage = newVal;
      },
      immediate: true
    },
    'pricing.margin_percentage': {
      handler(newVal) {
        this.localMarginPercentage = newVal;
      },
      immediate: true
    }
  }
};
</script>

<style scoped>
.pricing-tab {
  width: 100%;
  display: block;

  .table {
    margin: 0;
    width: 100%;
    table-layout: fixed;
    border-collapse: collapse;
    
    th, td {
      padding: 0.625rem 1rem;
      border-top: 1px solid #32383e;
      white-space: nowrap;
    }

    th {
      width: 50%;
      font-weight: 500;
      font-size: 0.9rem;
    }
    
    td {
      width: 50%;
      font-weight: 400;
      font-size: 0.9rem;

      .d-flex {
        justify-content: flex-end;
        align-items: center;
        gap: 0.5rem;
        
        .input-group {
          width: 80px;
          min-width: 80px;
          flex: 0 0 80px;
        }
        
        .value-display {
          text-align: right;
          min-width: 0;
          white-space: nowrap;
        }
      }
    }
    
    tr:first-child {
      th, td {
        border-top: none;
      }
    }
    
    .subtotal-row, .subtotal-with-waste-row {
      th, td {
        border-top: 2px solid #42b983;
        font-weight: 600;
      }
    }
    
    .total-row {
      th, td {
        border-top: 2px solid #42b983;
        font-weight: 700;
        font-size: 1rem;
      }
    }
    
    .final-price-row {
      th, td {
        font-weight: 700;
        color: #42b983;
        font-size: 1rem;
      }
    }
  }
  
  .input-group {
    .form-control {
      background-color: #1a1e21;
      border-color: #32383e;
      color: #f8f9fa;
      font-size: 0.9rem;
      padding: 0.25rem 0.5rem;
      text-align: right;
      
      &:focus {
        background-color: #1a1e21;
        border-color: #42b983;
        box-shadow: 0 0 0 0.25rem rgba(66, 185, 131, 0.25);
      }
    }
    
    .input-group-text {
      background-color: #1a1e21;
      border-color: #32383e;
      color: #adb5bd;
      font-size: 0.9rem;
      padding: 0.25rem 0.5rem;
    }
  }

  .value-display {
    min-width: 100px;
    text-align: right;
    font-size: 0.9rem;
  }
}
</style>