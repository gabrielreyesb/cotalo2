<template>
  <div class="extras-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-6 mb-3 mb-md-0 me-md-2">
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
            <div class="col-md-3 mb-3 mb-md-0 me-md-2">
              <label for="extra-quantity" class="form-label">Cantidad</label>
              <input 
                id="extra-quantity" 
                type="number" 
                v-model.number="quantity" 
                class="form-control" 
                min="1" 
                step="1"
                :disabled="!selectedExtraId"
              />
            </div>
            <div class="col-md-2 d-grid">
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

      <!-- Table view for medium and large screens -->
      <div v-if="productExtras.length" class="d-none d-md-block">
        <table class="table table-dark table-striped">
          <thead>
            <tr>
              <th>Descripción</th>
              <th>Precio unitario</th>
              <th>Cantidad</th>
              <th>Subtotal</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(extra, index) in productExtras" :key="index">
              <td>{{ extra.name }}</td>
              <td class="text-end">{{ formatCurrency(extra.unit_price) }}</td>
              <td class="text-center">{{ extra.quantity }}</td>
              <td class="text-end">{{ formatCurrency(extra.unit_price * extra.quantity) }}</td>
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
              <th class="text-end">{{ formatCurrency(totalCost) }}</th>
              <th></th>
            </tr>
          </tfoot>
        </table>
      </div>

      <!-- Card view for small screens -->
      <div v-if="productExtras.length" class="d-md-none">
        <div v-for="(extra, index) in productExtras" :key="index" class="card mb-3 shadow-sm">
          <div class="card-body p-2">
            <!-- First row: Extra description only -->
            <h6 class="card-title mb-2 text-truncate">{{ extra.name }}</h6>
            
            <!-- Second row: Material price and quantity -->
            <div class="row g-2 mb-2">
              <div class="col">
                <div class="badge bg-info d-block text-center p-2 w-100">
                  {{ formatCurrency(extra.unit_price) }}
                </div>
              </div>
              <div class="col">
                <div class="badge bg-secondary d-block text-center p-2 w-100">
                  {{ extra.quantity }}
                </div>
              </div>
            </div>
            
            <!-- Third row: Subtotal price and delete button -->
            <div class="d-flex justify-content-between align-items-center">
              <span class="badge bg-success fs-5">{{ formatCurrency(extra.unit_price * extra.quantity) }}</span>
              <button 
                class="btn btn-sm btn-outline-danger px-2 py-1" 
                @click="removeExtra(index)"
              >
                <i class="fa fa-trash fa-sm"></i>
              </button>
            </div>
          </div>
        </div>
        
        <!-- Total cost for small screens -->
        <div class="card bg-dark text-white">
          <div class="card-body py-2">
            <div class="d-flex justify-content-between align-items-center">
              <span class="fw-bold">Total extras:</span>
              <span class="fs-5">{{ formatCurrency(totalCost) }}</span>
            </div>
          </div>
        </div>
      </div>

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
    },
    productQuantity: {
      type: Number,
      default: 1
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
    },
    updateExtrasCalculations() {
      console.log('ExtrasTab: Recalculating extras with product quantity', this.productQuantity);
      
      // If we need to update calculations based on quantity in the future,
      // this is where we would do it
      
      // For now, just emit the current extras to ensure pricing gets updated
      this.$emit('update:product-extras', [...this.productExtras]);
    }
  },
  watch: {
    // Watch for changes to product quantity
    productQuantity() {
      console.log('ExtrasTab: Product quantity changed to', this.productQuantity);
      this.updateExtrasCalculations();
    },
    // Also watch for changes to extras array
    productExtras: {
      handler(newExtras) {
        console.log('ExtrasTab: Extras array changed, checking for recalculation flag');
        // Check if any extras have the recalculation flag
        const needsRecalculation = newExtras.some(extra => extra._needsRecalculation);
        
        if (needsRecalculation) {
          console.log('ExtrasTab: Found extras needing recalculation');
          this.updateExtrasCalculations();
        }
      },
      deep: true
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

/* Form controls with dark theme */
.form-select, 
.form-control {
  color: #e1e1e1 !important;
  background-color: #2c3136 !important;
  border: 1px solid #495057;
  border-radius: 4px;
}

.form-select:focus,
.form-control:focus {
  border-color: #42b983;
  background-color: #2c3136 !important;
  color: #e1e1e1 !important;
  box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25);
}

.form-select::placeholder,
.form-control::placeholder {
  color: #6c757d;
}

/* Add styling for select options */
.form-select option {
  color: #e1e1e1;
  background-color: #2c3136;
}

/* Green accent panel styling - Base */
.green-accent-panel > .card:not(.shadow-sm) {
  border-left: 4px solid #42b983;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
}

/* Table container styling */
.green-accent-panel > div:not(.card) {
  position: relative;
  padding-left: 0.5rem;
  margin-left: 0.5rem;
}

.green-accent-panel > div:not(.card)::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background-color: #42b983;
  border-radius: 4px;
}

/* Table styling */
.green-accent-panel > table.table {
  border-left: none;
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