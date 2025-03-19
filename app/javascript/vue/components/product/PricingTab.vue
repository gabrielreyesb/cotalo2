<template>
  <div class="pricing-tab">
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">Product Pricing</h5>
        
        <div class="row">
          <div class="col-md-6">
            <table class="table table-bordered">
              <tbody>
                <tr>
                  <th class="table-light" style="width: 40%">Materials Cost:</th>
                  <td>{{ formatCurrency(pricing.materials_cost) }}</td>
                </tr>
                <tr>
                  <th class="table-light">Processes Cost:</th>
                  <td>{{ formatCurrency(pricing.processes_cost) }}</td>
                </tr>
                <tr>
                  <th class="table-light">Extras Cost:</th>
                  <td>{{ formatCurrency(pricing.extras_cost) }}</td>
                </tr>
                <tr>
                  <th class="table-light">Subtotal:</th>
                  <td>{{ formatCurrency(pricing.subtotal) }}</td>
                </tr>
                <tr>
                  <th class="table-light">Waste ({{ pricing.waste_percentage }}%):</th>
                  <td>{{ formatCurrency(pricing.waste_value) }}</td>
                </tr>
                <tr>
                  <th class="table-light">Margin ({{ pricing.margin_percentage }}%):</th>
                  <td>{{ formatCurrency(pricing.margin_value) }}</td>
                </tr>
                <tr class="table-primary">
                  <th>Total Price:</th>
                  <td class="fw-bold">{{ formatCurrency(pricing.total_price) }}</td>
                </tr>
                <tr>
                  <th class="table-light">Price Per Piece:</th>
                  <td>{{ formatCurrency(pricing.final_price_per_piece) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          
          <div class="col-md-6">
            <div class="card h-100">
              <div class="card-body">
                <h5 class="card-title">Cost Breakdown</h5>
                <canvas id="costBreakdownChart" ref="chartCanvas"></canvas>
              </div>
            </div>
          </div>
        </div>
      </div>
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
    }
  },
  data() {
    return {
      chart: null
    };
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
    },
    initChart() {
      if (this.chart) {
        this.chart.destroy();
      }
      
      const ctx = this.$refs.chartCanvas.getContext('2d');
      
      const data = {
        labels: ['Materials', 'Processes', 'Extras', 'Waste', 'Margin'],
        datasets: [{
          data: [
            this.pricing.materials_cost || 0,
            this.pricing.processes_cost || 0,
            this.pricing.extras_cost || 0,
            this.pricing.waste_value || 0,
            this.pricing.margin_value || 0
          ],
          backgroundColor: [
            'rgba(54, 162, 235, 0.6)',
            'rgba(255, 99, 132, 0.6)',
            'rgba(255, 206, 86, 0.6)',
            'rgba(75, 192, 192, 0.6)',
            'rgba(153, 102, 255, 0.6)'
          ],
          borderColor: [
            'rgba(54, 162, 235, 1)',
            'rgba(255, 99, 132, 1)',
            'rgba(255, 206, 86, 1)',
            'rgba(75, 192, 192, 1)',
            'rgba(153, 102, 255, 1)'
          ],
          borderWidth: 1
        }]
      };
      
      this.chart = new Chart(ctx, {
        type: 'pie',
        data: data,
        options: {
          responsive: true,
          plugins: {
            legend: {
              position: 'right'
            },
            tooltip: {
              callbacks: {
                label: (context) => {
                  const label = context.label || '';
                  const value = context.raw;
                  const percentage = Math.round((value / this.pricing.total_price) * 100);
                  return `${label}: ${this.formatCurrency(value)} (${percentage}%)`;
                }
              }
            }
          }
        }
      });
    }
  },
  mounted() {
    // We need to import Chart.js
    this.$nextTick(() => {
      if (this.pricing) {
        this.initChart();
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
</style> 