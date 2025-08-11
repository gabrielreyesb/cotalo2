<template>
  <div class="pricing-tab">
    <table class="table mb-0">
      <tbody>
        <tr>
          <th style="width: 50%">{{ translations.pricing.materials_cost }}</th>
          <td class="text-end">{{ formatCurrency(pricing.materials_cost) }}</td>
        </tr>
        <tr>
          <th>Procesos aplicados:</th>
          <td class="text-end">{{ formatCurrency(pricing.material_processes_cost || 0) }}</td>
        </tr>
        <tr>
          <th>Procesos globales:</th>
          <td class="text-end">{{ formatCurrency(pricing.global_processes_cost || 0) }}</td>
        </tr>
        <tr :class="{ 'bg-danger bg-opacity-10': pricing.extras_cost > 0 && pricing.include_extras_in_subtotal === false }">
          <th>{{ translations.pricing.extras_cost }}</th>
          <td class="text-end">{{ formatCurrency(pricing.extras_cost) }}</td>
        </tr>
        <tr class="subtotal-row">
          <th>{{ translations.pricing.subtotal }}</th>
          <td class="text-end">{{ formatCurrency(pricing.subtotal) }}</td>
        </tr>

        <!-- BLOQUE MERMA -->
        <tr class="waste-row-1">
          <th class="align-middle">
            <div class="waste-label">% de merma:</div>
          </th>
          <td class="text-end">
            <div class="waste-input-container">
              <input
                type="number"
                class="form-control form-control-sm text-end waste-input"
                v-model.number="localWastePercentage"
                min="0"
                step="0.1"
                @change="handleWastePercentageChange"
              />
            </div>
          </td>
        </tr>

        <tr class="waste-row-2">
          <th class="value-label">Merma</th>
          <td class="text-end">
            <div class="waste-value">
              {{ formatCurrency(pricing.waste_value) }}
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

        <!-- BLOQUE MARGEN -->
        <tr class="margin-row-1">
          <th class="align-middle">
            <div class="margin-label">% de margen:</div>
          </th>
          <td class="text-end">
            <div class="margin-input-container">
              <input 
                type="number" 
                class="form-control form-control-sm text-end margin-input" 
                v-model.number="localMarginPercentage" 
                min="0"
                step="0.1"
                @change="handleMarginPercentageChange"
              />
            </div>
          </td>
        </tr>

        <tr class="margin-row-2">
          <th class="value-label">Margen</th>
          <td class="text-end">
            <div class="margin-value">
              {{ formatCurrency(pricing.margin_value) }}
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
    translations: {
      type: Object,
      required: true
    },
    userConfig: {
      type: Object,
      default: () => ({ waste_percentage: 0, margin_percentage: 0 })
    }
  },
  data() {
    return {
      localWastePercentage: this.pricing?.waste_percentage || this.userConfig?.waste_percentage || 0.0,
      localMarginPercentage: this.pricing?.margin_percentage || this.userConfig?.margin_percentage || 0.0
    }
  },
  methods: {
    formatCurrency(value) {
      if (value === null || value === undefined) return '$0.00'
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value)
    },
    handleWastePercentageChange() {
      this.$emit('waste-percentage-changed', this.localWastePercentage)
    },
    handleMarginPercentageChange() {
      this.$emit('margin-percentage-changed', this.localMarginPercentage)
    }
  },
  watch: {
    'pricing.waste_percentage'(newValue) {
      this.localWastePercentage = newValue || this.userConfig?.waste_percentage || 0.0
    },
    'pricing.margin_percentage'(newValue) {
      this.localMarginPercentage = newValue || this.userConfig?.margin_percentage || 0.0
    },
    'userConfig.waste_percentage'(newValue) {
      if (!this.pricing?.waste_percentage) {
        this.localWastePercentage = newValue || 0.0
      }
    },
    'userConfig.margin_percentage'(newValue) {
      if (!this.pricing?.margin_percentage) {
        this.localMarginPercentage = newValue || 0.0
      }
    }
  }
}
</script>

<style scoped>
.waste-input-container,
.margin-input-container {
  position: relative;
  display: inline-block;
}

.waste-input,
.margin-input {
  width: 70px;
  text-align: right;
}

/* Ocultar controles de spinner */
.waste-input::-webkit-outer-spin-button,
.waste-input::-webkit-inner-spin-button,
.margin-input::-webkit-outer-spin-button,
.margin-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.waste-input[type=number],
.margin-input[type=number] {
  -moz-appearance: textfield;
}

.waste-value,
.margin-value {
  font-weight: 500;
  color: #ffffff;
}

.subtotal-row th,
.subtotal-row td,
.subtotal-with-waste-row th,
.subtotal-with-waste-row td,
.total-row th,
.total-row td {
  color: var(--cotalo-green) !important;
  font-weight: 600;
}
</style>
