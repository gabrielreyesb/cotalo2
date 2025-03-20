<template>
  <div class="processes-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-6">
              <label for="process-select" class="form-label">Seleccionar proceso</label>
              <select 
                id="process-select" 
                v-model="selectedProcessId" 
                class="form-select"
                :disabled="!availableProcesses.length"
              >
                <option value="" disabled>Seleccionar un proceso para agregar</option>
                <option 
                  v-for="process in availableProcesses" 
                  :key="process.id" 
                  :value="process.id"
                >
                  {{ process.description }}
                </option>
              </select>
            </div>
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary" 
                @click="addProcess" 
                :disabled="!canAdd"
              >
                <i class="fa fa-plus me-1"></i> Agregar Proceso
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="!productProcesses.length" class="text-center my-5">
        <p class="text-muted">No hay procesos agregados. Selecciona un proceso y agrégalo al producto.</p>
      </div>

      <table v-else class="table table-dark table-striped">
        <thead>
          <tr>
            <th>Descripción</th>
            <th>Unidad</th>
            <th>Precio por Unidad</th>
            <th>Precio Total</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(process, index) in productProcesses" :key="index">
            <td>{{ process.description }}</td>
            <td>{{ process.unit }}</td>
            <td>{{ formatCurrency(process.unitPrice) }}</td>
            <td>{{ formatCurrency(process.price) }}</td>
            <td>
              <div class="btn-group">
                <button 
                  class="btn btn-sm btn-outline-danger" 
                  @click="removeProcess(index)"
                  title="Eliminar proceso"
                >
                  <i class="fa fa-trash"></i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <th colspan="3" class="text-end">Total:</th>
            <th>{{ formatCurrency(totalCost) }}</th>
            <th></th>
          </tr>
        </tfoot>
      </table>

      <!-- Global comments for all processes -->
      <div class="card mt-3 mb-4">
        <div class="card-body">
          <div class="form-group">
            <label for="process-comments" class="form-label">Comentarios sobre los procesos</label>
            <textarea 
              id="process-comments" 
              class="form-control" 
              v-model="globalComments" 
              rows="3"
              placeholder="Agregar notas o comentarios generales sobre los procesos de este producto"
              @change="updateGlobalComments"
            ></textarea>
          </div>
        </div>
      </div>
      
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProcessesTab',
  props: {
    productProcesses: {
      type: Array,
      default: () => []
    },
    availableProcesses: {
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
    totalSheets: {
      type: Number,
      default: 0
    },
    totalSquareMeters: {
      type: Number,
      default: 0
    }
  },
  data() {
    return {
      selectedProcessId: '',
      globalComments: this.comments || ''
    }
  },
  computed: {
    canAdd() {
      return this.selectedProcessId;
    },
    selectedProcess() {
      if (!this.selectedProcessId) return null;
      const process = this.availableProcesses.find(process => process.id === this.selectedProcessId);
      if (process) {
        console.log('Selected process:', process);
      }
      return process;
    },
    totalCost() {
      return this.productProcesses.reduce((sum, process) => {
        return sum + (parseFloat(process.price) || 0);
      }, 0);
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
    },
    addProcess() {
      if (!this.canAdd || !this.selectedProcess) return;
      
      const process = this.selectedProcess;
      const basePrice = parseFloat(process.price) || 0;
      let calculatedPrice = basePrice;
      
      // Calculate price based on unit type
      if (process.unit === 'pieza') {
        // For pieces: quantity of products * process price
        calculatedPrice = basePrice * this.productQuantity;
      } else if (process.unit === 'pliego') {
        // For sheets: materials sheets * process price
        calculatedPrice = basePrice * this.totalSheets;
      } else if (process.unit === 'mt2') {
        // For square meters: total square meters * process price
        calculatedPrice = basePrice * this.totalSquareMeters;
      }
      
      const newProcess = {
        id: process.id,
        description: process.description,
        unit: process.unit || 'unidad',
        unitPrice: basePrice, // Store the original unit price
        price: calculatedPrice // Store the calculated total price
      };
      
      const updatedProcesses = [...this.productProcesses, newProcess];
      this.$emit('update:product-processes', updatedProcesses);
      
      // Emit the total cost of processes
      this.$emit('update:processes-cost', this.totalCost + calculatedPrice);
      
      // Reset form
      this.selectedProcessId = '';
    },
    removeProcess(index) {
      if (confirm('¿Estás seguro de que quieres eliminar este proceso?')) {
        const processToRemove = this.productProcesses[index];
        const updatedProcesses = [...this.productProcesses];
        updatedProcesses.splice(index, 1);
        
        this.$emit('update:product-processes', updatedProcesses);
        
        // Calculate and emit the new total cost
        const newTotalCost = this.totalCost - (parseFloat(processToRemove.price) || 0);
        this.$emit('update:processes-cost', newTotalCost);
      }
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    }
  },
  mounted() {
    console.log('ProcessesTab mounted with props:', {
      productProcesses: this.productProcesses,
      availableProcesses: this.availableProcesses,
      comments: this.comments,
      productQuantity: this.productQuantity,
      totalSheets: this.totalSheets,
      totalSquareMeters: this.totalSquareMeters
    });
    
    // Emit initial processes cost when component mounts
    this.$emit('update:processes-cost', this.totalCost);
  }
}
</script>

<style scoped>
.processes-tab {
  position: relative;
}

/* Green accent panel styling */
.green-accent-panel > .card,
.green-accent-panel > div > .card {
  border-left: 4px solid #42b983;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
}

.green-accent-panel > table.table {
  border-left: 4px solid #42b983;
  margin-left: 0.5rem;
}

/* No processes message styling */
.green-accent-panel > .text-center {
  border-left: 4px solid #42b983;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
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
  border-collapse: separate;
  border-spacing: 0;
}

.table-dark {
  background-color: #23272b;
  color: #e9ecef;
}

.table-dark th {
  background-color: #32383e;
}

.table-striped > tbody > tr:nth-of-type(odd) {
  background-color: rgba(255, 255, 255, 0.05);
}

.table th,
.table td {
  border-top-color: #32383e;
  padding: 0.75rem;
}

.table thead th {
  border-bottom-color: #32383e;
}

/* Form controls with green focus */
.form-select, 
.form-control {
  color: #e1e1e1;
  background-color: #2c3136;
  border: 1px solid #495057;
  border-radius: 4px;
}

/* Add styling for select options */
.form-select option {
  color: #212529;
  background-color: #fff;
}

.form-select:focus,
.form-control:focus {
  border-color: #42b983;
  background-color: #2c3136;
  color: #e1e1e1;
  box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25);
}

.form-select::placeholder,
.form-control::placeholder {
  color: #6c757d;
}

/* Label styling */
.form-label {
  color: #adb5bd;
  margin-bottom: 0.5rem;
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

.btn-outline-secondary,
.btn-outline-danger {
  color: #adb5bd;
  border-color: #495057;
}

.btn-outline-secondary:hover {
  background-color: #495057;
  color: #fff;
  border-color: #495057;
}

.btn-outline-danger:hover {
  background-color: #dc3545;
  color: #fff;
}

/* Text colors */
.text-muted {
  color: #6c757d !important;
}

.text-end {
  text-align: right !important;
}
</style> 