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
                class="form-control bg-dark text-white border-secondary" 
                style="color-scheme: dark;"
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
        <div class="form-check mb-3">
          <input 
            class="form-check-input" 
            type="checkbox" 
            id="include-extras-subtotal" 
            v-model="includeInSubtotal"
            @change="updateIncludeInSubtotal"
          >
          <label class="form-check-label" for="include-extras-subtotal">
            Incluir extras al valor del producto
          </label>
        </div>
        <table class="table table-dark table-striped">
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Descripción</th>
              <th class="text-end" style="width: 150px;">Precio unitario</th>
              <th class="text-center" style="width: 150px;">Cantidad</th>
              <th class="text-end" style="width: 180px;">Total</th>
              <th class="text-center" style="width: 80px;">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(extra, index) in productExtras" :key="index">
              <td>{{ extra.name }}</td>
              <td>{{ extra.description }}</td>
              <td class="text-end" style="width: 150px;">
                <input
                  type="number"
                  class="form-control form-control-sm text-end"
                  v-model.number="extra.unit_price"
                  @change="updateExtraPrice(index)"
                  min="0"
                  step="0.01"
                  title="Editar precio del extra"
                  data-toggle="tooltip"
                  style="width: 100px;"
                >
              </td>
              <td class="text-center" style="width: 150px;">
                <div class="input-group input-group-sm">
                  <input 
                    type="number" 
                    class="form-control form-control-sm text-center"
                    v-model.number="extra.quantity"
                    min="1"
                    @change="updateExtraQuantity(index)"
                    title="Editar cantidad"
                    data-toggle="tooltip"
                    style="width: 80px;"
                  >
                  <span class="input-group-text">{{ extra.unit }}</span>
                </div>
              </td>
              <td class="text-end" style="width: 180px;">{{ formatCurrency(calculateExtraTotal(extra)) }}</td>
              <td class="text-center" style="width: 80px;">
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
              <th colspan="4" class="text-end">Total:</th>
              <th class="text-end">{{ formatCurrency(totalCost) }}</th>
              <th></th>
            </tr>
          </tfoot>
        </table>
      </div>

      <!-- Card view for small screens -->
      <div v-if="productExtras.length" class="d-md-none">
        <div class="form-check mb-3">
          <input 
            class="form-check-input" 
            type="checkbox" 
            id="include-extras-subtotal-mobile" 
            v-model="includeInSubtotal"
            @change="updateIncludeInSubtotal"
          >
          <label class="form-check-label" for="include-extras-subtotal-mobile">
            Incluir extras en el subtotal del producto
          </label>
        </div>
        <div v-for="(extra, index) in productExtras" :key="index" class="card mb-3 shadow-sm">
          <div class="card-body p-2">
            <!-- First row: Extra description only -->
            <h6 class="card-title mb-2">{{ extra.name }}</h6>
            
            <!-- Second row: Material price and quantity -->
            <div class="row g-2 mb-2">
              <div class="col-6">
                <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                  {{ formatCurrency(extra.unit_price) }}
                </div>
              </div>
              <div class="col-6">
                <input 
                  type="number" 
                  class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge bg-dark text-white"
                  v-model.number="extra.quantity" 
                  min="1"
                  @change="updateExtraQuantity(index)"
                  title="Haz clic para editar la cantidad"
                />
              </div>
            </div>
            
            <!-- Third row: Total price and delete button -->
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
            <div class="d-flex justify-content-end align-items-center">
              <span class="fw-bold me-3">Total:</span>
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
import { ref } from 'vue'

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
    },
    includeExtrasInSubtotal: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      selectedExtraId: '',
      quantity: 1,
      globalComments: this.comments || '',
      includeInSubtotal: this.includeExtrasInSubtotal
    }
  },
  computed: {
    canAdd() {
      return this.selectedExtraId && this.quantity > 0;
    },
    selectedExtra() {
      if (!this.selectedExtraId) return null;
      const extra = this.availableExtras.find(extra => extra.id === this.selectedExtraId);
      return extra;
    },
    totalCost() {
      return this.productExtras.reduce((sum, extra) => sum + extra.total, 0);
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('es-AR', {
        style: 'currency',
        currency: 'ARS'
      }).format(value);
    },
    calculateExtraTotal(extra) {
      return extra.total;
    },
    updateExtraQuantity(index) {
      const extra = this.productExtras[index];
      if (extra.quantity < 1) {
        extra.quantity = 1;
      }
      extra.total = extra.unit_price * extra.quantity;
      this.$emit('update:product-extras', this.productExtras);
      this.$emit('update:extras-cost', this.totalCost);
    },
    updateExtraPrice(index) {
      const extra = this.productExtras[index];
      if (extra.unit_price < 0) {
        extra.unit_price = 0;
      }
      extra.total = extra.unit_price * extra.quantity;
      this.$emit('update:product-extras', this.productExtras);
      this.$emit('update:extras-cost', this.totalCost);
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
        total: this.selectedExtra.unit_price * this.quantity,
        comments: ''
      };
      
      const updatedExtras = [...this.productExtras, newExtra];
      this.$emit('update:product-extras', updatedExtras);
      this.$emit('update:extras-cost', this.totalCost);
      
      // Reset form
      this.selectedExtraId = '';
      this.quantity = 1;
    },
    removeExtra(index) {
      const updatedExtras = [...this.productExtras];
      updatedExtras.splice(index, 1);
      this.$emit('update:product-extras', updatedExtras);
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    },
    updateExtrasCalculations() {      
      // For now, just emit the current extras to ensure pricing gets updated
      this.$emit('update:product-extras', [...this.productExtras]);
    },
    updateIncludeInSubtotal() {
      this.$emit('update:include-extras-in-subtotal', this.includeInSubtotal);
    }
  },
  watch: {
    // Watch for changes to product quantity
    productQuantity() {
      this.updateExtrasCalculations();
    },
    // Also watch for changes to extras array
    productExtras: {
      handler(newExtras) {
        // Check if any extras have the recalculation flag
        const needsRecalculation = newExtras.some(extra => extra._needsRecalculation);
        
        if (needsRecalculation) {
          this.updateExtrasCalculations();
        }
      },
      deep: true
    }
  },
  mounted() {
    // Need to import Bootstrap Modal JS
    import('bootstrap/js/dist/modal');
  }
}
</script>