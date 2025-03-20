<template>
  <div class="pricing-tab">
    <div class="green-accent-panel mb-4">
      <h5 class="card-title">Resumen de Precios</h5>
    </div>
    
    <div class="row">
      <div class="col-md-8">
        <table class="table table-dark table-bordered">
          <tbody>
            <tr class="table-primary">
              <th style="width: 40%">Costo de Materiales:</th>
              <td class="fw-bold">{{ formatCurrency(pricing.materials_cost) }}</td>
            </tr>
            <tr class="table-warning">
              <th>Costo de Procesos:</th>
              <td class="fw-bold">{{ formatCurrency(pricing.processes_cost) }}</td>
            </tr>
            <tr class="table-info">
              <th>Costo de Extras:</th>
              <td class="fw-bold">{{ formatCurrency(pricing.extras_cost) }}</td>
            </tr>
            <tr>
              <th>Subtotal:</th>
              <td>{{ formatCurrency(pricing.subtotal) }}</td>
            </tr>
            <tr>
              <th>Desperdicio ({{ pricing.waste_percentage }}%):</th>
              <td>{{ formatCurrency(pricing.waste_value) }}</td>
            </tr>
            <tr>
              <th>Precio por Pieza (antes del margen):</th>
              <td>{{ formatCurrency(pricing.price_per_piece_before_margin) }}</td>
            </tr>
            <tr>
              <th>Margen ({{ pricing.margin_percentage }}%):</th>
              <td>{{ formatCurrency(pricing.margin_value) }}</td>
            </tr>
            <tr class="table-success">
              <th>Precio Total:</th>
              <td class="fw-bold">{{ formatCurrency(pricing.total_price) }}</td>
            </tr>
            <tr class="table-success">
              <th>Precio por Pieza:</th>
              <td class="fw-bold">{{ formatCurrency(pricing.final_price_per_piece) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <div class="col-md-4">
        <div class="card">
          <div class="card-body">
            <h5 class="card-title">Desglose de Costos</h5>
            <div class="chart-container" style="position: relative; height: 260px;">
              <canvas ref="pricingChart"></canvas>
            </div>
          </div>
        </div>
      </div>
    </div>
    
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
import Chart from 'chart.js/auto';

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
      pricingChart: null,
      saving: false
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
      this.saving = true;
      this.$emit('save:product');
    },
    initChart() {
      try {
        if (!this.pricing) return;
        
        // Destroy previous chart if it exists
        if (this.pricingChart) {
          this.pricingChart.destroy();
        }

        // Check if canvas element exists
        if (!this.$refs.pricingChart) {
          console.warn('Chart canvas element not found');
          return;
        }

        const ctx = this.$refs.pricingChart.getContext('2d');
        
        // Ensure we have non-zero values for the chart
        const materialsValue = this.pricing.materials_cost || 0;
        const processesValue = this.pricing.processes_cost || 0;
        const extrasValue = this.pricing.extras_cost || 0;
        const wasteValue = this.pricing.waste_value || 0;
        const marginValue = this.pricing.margin_value || 0;
        
        // Determine if we should use real data or placeholders
        const hasData = materialsValue > 0 || processesValue > 0 || extrasValue > 0 || wasteValue > 0 || marginValue > 0;
        
        // Only show non-zero costs for clarity
        const chartData = [];
        const labels = [];
        const colors = [];
        
        if (materialsValue > 0 || !hasData) {
          chartData.push(hasData ? materialsValue : 10);
          labels.push('Materiales');
          colors.push('#0275d8'); // Bootstrap primary color
        }
        
        if (processesValue > 0 || !hasData) {
          chartData.push(hasData ? processesValue : 15);
          labels.push('Procesos');
          colors.push('#f0ad4e'); // Bootstrap warning color
        }
        
        if (extrasValue > 0 || !hasData) {
          chartData.push(hasData ? extrasValue : 35);
          labels.push('Extras');
          colors.push('#5bc0de'); // Bootstrap info color
        }
        
        if (wasteValue > 0 || !hasData) {
          chartData.push(hasData ? wasteValue : 15);
          labels.push('Desperdicio');
          colors.push('#ffcd56');
        }
        
        if (marginValue > 0 || !hasData) {
          chartData.push(hasData ? marginValue : 25);
          labels.push('Margen');
          colors.push('#42b983');
        }
        
        this.pricingChart = new Chart(ctx, {
          type: 'pie',
          data: {
            labels: labels,
            datasets: [{
              data: chartData,
              backgroundColor: colors
            }]
          },
          options: {
            responsive: true,
            plugins: {
              legend: {
                position: 'right',
                labels: {
                  color: '#e1e1e1'
                }
              },
              tooltip: {
                callbacks: {
                  label: (tooltipItem) => {
                    const value = tooltipItem.raw;
                    const total = tooltipItem.dataset.data.reduce((a, b) => a + b, 0);
                    const percentage = Math.round((value / total) * 100);
                    return `${tooltipItem.label}: ${this.formatCurrency(value)} (${percentage}%)`;
                  }
                }
              }
            }
          }
        });
      } catch (error) {
        console.error('Error initializing chart:', error);
      }
    }
  },
  mounted() {
    // Initialize the chart after component is mounted
    this.$nextTick(() => {
      try {
        this.initChart();
      } catch (error) {
        console.error('Error in pricing tab mounted hook:', error);
      }
    });
  },
  watch: {
    pricing: {
      handler() {
        this.$nextTick(() => {
          this.initChart();
        });
      },
      deep: true
    }
  }
};
</script>

<style scoped>
.pricing-tab {
  position: relative;
}

.green-accent-panel {
  border-left: 3px solid #42b983;
  padding-left: 1rem;
}

/* Card styling with green accent */
.card {
  background-color: #23272b;
  border-color: #32383e;
  margin-bottom: 1.5rem;
  box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.15);
}

.card-body {
  padding: 1rem;
}

.card-title {
  color: #e1e1e1;
  font-weight: 600;
  margin-bottom: 1rem;
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

.table-success {
  background-color: rgba(66, 185, 131, 0.2) !important;
}

.table-success th, 
.table-success td {
  color: #42b983;
}

.table-info {
  background-color: rgba(54, 162, 235, 0.2) !important;
}

.table-info th,
.table-info td {
  color: #36a2eb;
}

.table th,
.table td {
  border-color: #32383e;
  padding: 0.75rem;
}

.fw-bold {
  font-weight: bold;
}
</style> 