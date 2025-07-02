<template>
  <div class="pricing-tab">
    <table class="table mb-0">
      <tbody>
        <tr>
          <th style="width: 50%">{{ translations.pricing.materials_cost }}</th>
          <td class="text-end">{{ formatCurrency(pricing.materials_cost) }}</td>
        </tr>
        <tr>
          <th>{{ translations.pricing.processes_cost }}</th>
          <td class="text-end">{{ formatCurrency(pricing.processes_cost) }}</td>
        </tr>
        <tr :class="{ 'bg-danger bg-opacity-10': pricing.extras_cost > 0 && pricing.include_extras_in_subtotal === false }">
          <th>{{ translations.pricing.extras_cost }}</th>
          <td class="text-end">{{ formatCurrency(pricing.extras_cost) }}</td>
        </tr>
        <tr class="subtotal-row">
          <th>{{ translations.pricing.subtotal }}</th>
          <td class="text-end">{{ formatCurrency(pricing.subtotal) }}</td>
        </tr>
        <tr>
          <th class="align-middle">{{ translations.pricing.waste }}</th>
          <td>
            <div class="d-flex justify-content-end align-items-center">
              <div class="percentage-group">
                <div class="input-group input-group-sm">
                  <input 
                    type="number" 
                    class="form-control form-control-sm text-end waste-input" 
                    v-model.number="localWastePercentage" 
                    min="0"
                    step="0.1"
                    @change="handleWastePercentageChange"
                  />
                  <span class="input-group-text">%</span>
                </div>
              </div>
              <div class="calculated-value">
                {{ formatCurrency(pricing.waste_value) }}
              </div>
            </div>
          </td>
        </tr>
        <tr class="subtotal-with-waste-row">
          <th>{{ translations.pricing.subtotal_with_waste }}</th>
          <td class="text-end">{{ formatCurrency(pricing.subtotal + pricing.waste_value) }}</td>
        </tr>
        <tr class="price-before-margin-row">
          <th>{{ translations.pricing.price_per_piece_before_margin }}</th>
          <td class="text-end">{{ formatCurrency(pricing.price_per_piece_before_margin) }}</td>
        </tr>
        <tr>
          <th class="align-middle">{{ translations.pricing.margin }}</th>
          <td>
            <div class="d-flex justify-content-end align-items-center">
              <div class="percentage-group">
                <div class="input-group input-group-sm">
                  <input 
                    type="number" 
                    class="form-control form-control-sm text-end margin-input" 
                    v-model.number="localMarginPercentage" 
                    min="0"
                    step="0.1"
                    @change="handleMarginPercentageChange"
                  />
                  <span class="input-group-text">%</span>
                </div>
              </div>
              <div class="calculated-value">
                {{ formatCurrency(pricing.margin_value) }}
              </div>
            </div>
          </td>
        </tr>
        <tr class="total-row">
          <th>{{ translations.pricing.total_price }}</th>
          <td class="text-end">{{ formatCurrency(pricing.total_price) }}</td>
        </tr>
        <tr class="final-price-row">
          <th>{{ translations.pricing.final_price_per_piece }}</th>
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
    },
    translations: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      localWastePercentage: this.pricing.waste_percentage || 0,
      localMarginPercentage: this.pricing.margin_percentage || 0
    };
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
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
        this.localWastePercentage = newVal || 0;
      },
      immediate: true
    },
    'pricing.margin_percentage': {
      handler(newVal) {
        this.localMarginPercentage = newVal;
      },
      immediate: true
    },
    'suggestedMargin': {
      handler(newVal) {
        if (newVal !== this.localMarginPercentage) {
          this.localMarginPercentage = newVal;
          this.handleMarginPercentageChange();
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="scss">
.pricing-tab {
  width: 100%;
  display: block;

  .table {
    th, td {
      width: 50%;
    }

    td {
      .d-flex {
        justify-content: flex-end;
        align-items: center;
        
        .percentage-group {
          width: 140px;
          margin-right: 10px;
          
          .input-group {
            width: 100%;
          }
        }
        
        .calculated-value {
          width: 120px;
          text-align: right;
          white-space: nowrap;
        }
      }
    }
    
    .subtotal-row, .subtotal-with-waste-row, .price-before-margin-row {
      th, td {
        border-top: 2px solid #42b983;
        font-weight: 600;
      }
    }
    
    .total-row {
      th, td {
        border-top: 2px solid var(--cotalo-green);
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

  .pricing-tab .table th,
  .pricing-tab .table td {
    background-color: var(--card-bg) !important;
    color: var(--text-primary) !important;
  }

  .waste-input, .margin-input {
    width: 50px !important;
    min-width: 50px;
    max-width: 60px;
    text-align: right;
  }
}
</style>