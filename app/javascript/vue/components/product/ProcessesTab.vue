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
            <th>Ancho</th>
            <th>Largo</th>
            <th>Unidad</th>
            <th>Precio</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(process, index) in productProcesses" :key="index">
            <td>{{ process.description }}</td>
            <td>{{ process.width }}</td>
            <td>{{ process.length }}</td>
            <td>{{ process.unit }}</td>
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
      
      const newProcess = {
        id: this.selectedProcess.id,
        description: this.selectedProcess.description,
        width: this.selectedProcess.width || 0,
        length: this.selectedProcess.length || 0,
        unit: this.selectedProcess.unit || 'unidad',
        price: this.selectedProcess.price || 0
      };
      
      const updatedProcesses = [...this.productProcesses, newProcess];
      this.$emit('update:product-processes', updatedProcesses);
      
      // Reset form
      this.selectedProcessId = '';
    },
    removeProcess(index) {
      if (confirm('¿Estás seguro de que quieres eliminar este proceso?')) {
        const updatedProcesses = [...this.productProcesses];
        updatedProcesses.splice(index, 1);
        this.$emit('update:product-processes', updatedProcesses);
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
      comments: this.comments
    });
  }
}
</script>

<style scoped>
.processes-tab {
  position: relative;
}

/* Card styling with green accent */
.card {
  background-color: #23272b;
  border-color: #32383e;
  border-left: 2px solid #42b983;
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