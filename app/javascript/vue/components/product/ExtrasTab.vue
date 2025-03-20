<template>
  <div class="extras-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-6">
              <label for="extra-select" class="form-label">Seleccionar extra</label>
              <select 
                id="extra-select" 
                v-model="selectedExtraId" 
                class="form-select"
                :disabled="!availableExtras.length"
              >
                <option value="" disabled>Seleccionar un extra para agregar</option>
                <option 
                  v-for="extra in availableExtras" 
                  :key="extra.id" 
                  :value="extra.id"
                >
                  {{ extra.name }}
                </option>
              </select>
            </div>
            <div class="col-md-3">
              <label for="extra-quantity" class="form-label">Cantidad</label>
              <input 
                id="extra-quantity" 
                type="number" 
                v-model.number="quantity" 
                class="form-control" 
                min="1" 
                step="1"
                :disabled="!selectedExtraId"
              >
            </div>
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary" 
                @click="addExtra" 
                :disabled="!canAdd"
              >
                <i class="fa fa-plus me-1"></i> Agregar Extra
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="!productExtras.length" class="text-center my-5">
        <p class="text-muted">No hay extras agregados. Selecciona un extra y agrégalo al producto.</p>
      </div>

      <table v-else class="table table-dark table-striped">
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Precio unitario</th>
            <th>Cantidad</th>
            <th>Subtotal</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(extra, index) in productExtras" :key="index">
            <td>{{ extra.name }}</td>
            <td>{{ formatCurrency(extra.unit_price) }}</td>
            <td>{{ extra.quantity }}</td>
            <td>{{ formatCurrency(extra.unit_price * extra.quantity) }}</td>
            <td>
              <div class="btn-group">
                <button 
                  class="btn btn-sm btn-outline-danger" 
                  @click="removeExtra(index)"
                  title="Eliminar extra"
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

      <!-- Global comments for all extras -->
      <div class="card mt-3 mb-4">
        <div class="card-body">
          <div class="form-group">
            <label for="global-comments" class="form-label">Comentarios sobre los extras</label>
            <textarea 
              id="global-comments" 
              class="form-control" 
              v-model="globalComments" 
              rows="3"
              placeholder="Agregar notas o comentarios generales sobre los extras de este producto"
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
  name: 'ExtrasTab',
  props: {
    productExtras: {
      type: Array,
      default: () => []
    },
    availableExtras: {
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
      selectedExtraId: '',
      quantity: 1,
      globalComments: this.comments || ''
    }
  },
  computed: {
    canAdd() {
      return this.selectedExtraId && this.quantity > 0;
    },
    selectedExtra() {
      if (!this.selectedExtraId) return null;
      const extra = this.availableExtras.find(extra => extra.id === this.selectedExtraId);
      if (extra) {
        console.log('Selected extra:', extra);
      }
      return extra;
    },
    totalCost() {
      return this.productExtras.reduce((sum, extra) => {
        return sum + (extra.unit_price * extra.quantity);
      }, 0);
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value);
    },
    addExtra() {
      if (!this.canAdd || !this.selectedExtra) return;
      
      const newExtra = {
        id: this.selectedExtra.id,
        name: this.selectedExtra.name,
        description: this.selectedExtra.description,
        unit_price: this.selectedExtra.unit_price,
        unit: this.selectedExtra.unit,
        quantity: this.quantity,
        comments: ''
      };
      
      const updatedExtras = [...this.productExtras, newExtra];
      this.$emit('update:product-extras', updatedExtras);
      
      // Reset form
      this.selectedExtraId = '';
      this.quantity = 1;
    },
    removeExtra(index) {
      if (confirm('¿Estás seguro de que quieres eliminar este extra?')) {
        const updatedExtras = [...this.productExtras];
        updatedExtras.splice(index, 1);
        this.$emit('update:product-extras', updatedExtras);
      }
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    }
  },
  mounted() {
    console.log('ExtrasTab mounted with props:', {
      productExtras: this.productExtras,
      availableExtras: this.availableExtras,
      comments: this.comments
    });
    
    // Need to import Bootstrap Modal JS
    import('bootstrap/js/dist/modal');
  }
}
</script>

<style scoped>
.extras-tab {
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

/* Modal styling */
.modal-content {
  background-color: #2c3136;
  border-color: #495057;
}

.modal-header {
  border-bottom-color: #32383e;
}

.modal-footer {
  border-top-color: #32383e;
}

.modal-title {
  color: #f8f9fa;
}
</style> 