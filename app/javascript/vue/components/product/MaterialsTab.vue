<template>
  <div class="materials-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-9 mb-3 mb-md-0">
              <div class="d-flex align-items-center">
                <label for="material-select" class="form-label mb-0 me-2">Seleccionar material</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  title="<strong>Cómo se calculan los costos:</strong><br>
                  • <u>Piezas por material</u>: Cantidad de piezas que se pueden obtener de un pliego de material<br>
                  • <u>Total pliegos</u>: Cantidad de pliegos de material necesarios para crear el producto<br>
                  • <u>Total m²</u>: Cantidad de metros cuadrados de material necesarios para crear el producto<br>
                  • <u>Precio total</u>: Precio total del material para crear el producto"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
              <select 
                id="material-select" 
                v-model="materialIdForAdd" 
                class="form-select bg-dark text-white border-secondary"
                :disabled="!availableMaterials.length"
                @change="onMaterialSelect"
              >
                <option value="" disabled>Seleccionar un material para agregar</option>
                <option 
                  v-for="material in availableMaterials" 
                  :key="material.id" 
                  :value="material.id"
                >
                  {{ material.description }}
                </option>
              </select>
              <div v-if="validationMessage" class="text-danger mt-2">
                {{ validationMessage }}
              </div>
            </div>
            
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary w-100" 
                @click="addMaterial" 
                :disabled="!canAdd"
                :title="validationMessage"
              >
                <i class="fa fa-plus me-1"></i> Agregar material
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- No Materials Message -->
      <div v-if="!productMaterials.length" class="text-center my-5">
        <p class="text-muted">No hay materiales agregados. Selecciona un material y agrégalo al producto.</p>
      </div>

      <!-- Materials Table/Cards -->
      <div class="card mt-4" v-if="productMaterials.length">
        <div class="card-body p-0">
          <!-- Desktop Table -->
          <div class="d-none d-md-block">
            <table class="table table-dark table-striped product-table mb-0">
              <thead>
                <tr>
                  <th style="width: 40%">Descripción</th>
                  <th style="width: 12%">Ancho (cm)</th>
                  <th style="width: 12%">Largo (cm)</th>
                  <th style="width: 12%">Precio</th>
                  <th style="width: 12%">Piezas por material</th>
                  <th style="width: 12%">Total pliegos</th>
                  <th style="width: 12%">Total m²</th>
                  <th style="width: 12%">Precio total</th>
                  <th style="width: 8%">Acciones</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(material, index) in productMaterials" :key="index">
                  <td>{{ material.description }}</td>
                  <td>
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.ancho" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Editar ancho del material"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td>
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.largo" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Editar largo del material"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td>
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end" 
                      v-model.number="material.price" 
                      min="0"
                      step="0.01"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Editar precio del material"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-center">
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.piecesPerMaterial" 
                      min="1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Puedes editar este valor manualmente para ajustar la cantidad de piezas por material"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-center">{{ material.totalSheets }}</td>
                  <td class="text-center">{{ material.totalSquareMeters.toFixed(2) }}</td>
                  <td class="text-end">{{ formatCurrency(material.totalPrice) }}</td>
                  <td>
                    <div class="btn-group">
                      <input
                        type="radio"
                        :id="'material-radio-' + index"
                        :value="material.id"
                        v-model="selectedMaterial"
                        class="form-check-input me-2"
                      />
                      <button 
                        class="btn btn-sm btn-outline-danger" 
                        @click="removeMaterial(index)"
                        title="Eliminar material"
                      >
                        <i class="fa fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <th colspan="7" class="text-end">Total:</th>
                  <th class="text-end">{{ formatCurrency(totalCost) }}</th>
                  <th></th>
                </tr>
              </tfoot>
            </table>
          </div>
          
          <!-- Mobile Cards -->
          <div class="d-md-none">
            <div v-for="(material, index) in productMaterials" :key="index" class="card mb-3 shadow-sm">
              <div class="card-body p-2">
                <!-- First row: Material description only -->
                <h6 class="card-title mb-2">{{ material.description }}</h6>
                <!-- Second row: Width, length, price -->
                <div class="row g-2 mb-2">
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.ancho" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      placeholder="Ancho"
                    />
                  </div>
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.largo" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      placeholder="Largo"
                    />
                  </div>
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.price" 
                      min="0"
                      step="0.01"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      placeholder="Precio"
                    />
                  </div>
                </div>
                <!-- Rest of mobile card remains the same -->
                <div class="row g-2 mb-2">
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.piecesPerMaterial" 
                      min="1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Puedes editar este valor manualmente para ajustar la cantidad de piezas por material"
                    />
                  </div>
                  <div class="col-4">
                    <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                      {{ material.totalSheets }} pgs
                    </div>
                  </div>
                  <div class="col-4">
                    <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                      {{ material.totalSquareMeters.toFixed(1) }}
                    </div>
                  </div>
                </div>
                <!-- Fourth row: Total price and action buttons -->
                <div class="d-flex justify-content-between align-items-center">
                  <span class="badge bg-success fs-5">{{ formatCurrency(material.totalPrice) }}</span>
                  <div class="d-flex align-items-center">
                    <input
                      type="radio"
                      :id="'material-radio-mobile-' + index"
                      :value="material.id"
                      v-model="selectedMaterial"
                      class="form-check-input me-2"
                    />
                    <button 
                      class="btn btn-sm btn-outline-danger px-2 py-1" 
                      @click="removeMaterial(index)"
                    >
                      <i class="fa fa-trash fa-sm"></i>
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <!-- Total cost for small screens -->
            <div class="card bg-dark text-white">
              <div class="card-body py-2">
                <div class="d-flex justify-content-between align-items-center">
                  <span class="fw-bold">Total materiales:</span>
                  <span class="fs-5">{{ formatCurrency(totalCost) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Comments Section -->
      <div class="card mt-3 mb-4">
        <div class="card-body">
          <div class="form-group">
            <label for="material-comments" class="form-label">Comentarios sobre los materiales</label>
            <textarea 
              id="material-comments" 
              class="form-control" 
              v-model="globalComments" 
              rows="3"
              placeholder="Agregar notas o comentarios generales sobre los materiales de este producto"
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
  name: 'MaterialsTab',
  props: {
    productMaterials: {
      type: Array,
      required: true
    },
    availableMaterials: {
      type: Array,
      required: true
    },
    comments: {
      type: String,
      default: ''
    },
    productWidth: {
      type: Number,
      default: 0
    },
    productLength: {
      type: Number,
      default: 0
    },
    productQuantity: {
      type: Number,
      default: 1
    },
    selectedMaterialId: {
      type: Number,
      default: null
    },
    widthMargin: {
      type: Number,
      default: 0
    },
    lengthMargin: {
      type: Number,
      default: 0
    }
  },
  data() {
    return {
      materialIdForAdd: '',
      selectedMaterial: this.selectedMaterialId,
      globalComments: this.comments,
      validationMessage: ''
    };
  },
  computed: {
    canAdd() {
      if (!this.materialIdForAdd) {
        this.validationMessage = '';
        return false;
      }

      // Validate product dimensions and quantity
      if (!this.productQuantity || this.productQuantity <= 0) {
        this.validationMessage = 'Por favor, especifica la cantidad de piezas del producto en la pestaña de información general';
        return false;
      }
      if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
        this.validationMessage = 'Por favor, especifica el ancho y largo del producto en la pestaña de información general';
        return false;
      }

      return this.materialIdForAdd && this.selectedMaterialDetails;
    },
    selectedMaterialDetails() {
      if (!this.materialIdForAdd) return null;
      return this.availableMaterials.find(m => m.id === this.materialIdForAdd);
    },
    totalCost() {
      return this.productMaterials.reduce((sum, material) => sum + material.totalPrice, 0);
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
    },
    onMaterialSelect() {
      if (!this.materialIdForAdd) {
        this.validationMessage = '';
        return;
      }

      // Validate product dimensions and quantity
      if (!this.productQuantity || this.productQuantity <= 0) {
        this.validationMessage = 'Por favor, especifica la cantidad de piezas del producto en la pestaña de información general';
        return;
      }
      if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
        this.validationMessage = 'Por favor, especifica el ancho y largo del producto en la pestaña de información general';
        return;
      }

      this.validationMessage = '';
    },
    addMaterial() {
      if (!this.selectedMaterialDetails) {
        this.validationMessage = 'Por favor, selecciona un material.';
        return;
      }

      // Calculate initial pieces per material
      const initialPiecesPerSheet = this.calculatePiecesPerSheet(
        this.selectedMaterialDetails.ancho,
        this.selectedMaterialDetails.largo,
        this.productWidth,
        this.productLength,
        this.widthMargin,
        this.lengthMargin
      );

      const material = {
        id: this.selectedMaterialDetails.id,
        description: this.selectedMaterialDetails.description,
        client_description: this.selectedMaterialDetails.client_description,
        resistance: this.selectedMaterialDetails.resistance,
        ancho: this.selectedMaterialDetails.ancho,
        largo: this.selectedMaterialDetails.largo,
        price: this.selectedMaterialDetails.price,
        piecesPerMaterial: initialPiecesPerSheet || 1,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0
      };

      // Add to materials array
      this.productMaterials.push(material);
      
      // Calculate initial values
      this.updateMaterialCalculations({ index: this.productMaterials.length - 1, updatePiecesPerMaterial: true, material });
      
      // Reset selection
      this.materialIdForAdd = '';
      this.validationMessage = '';
      
      // If this is the first material, select it automatically
      if (this.productMaterials.length === 1) {
        this.selectedMaterial = material.id;
      }
      
      // Emit update event
      this.$emit('update:product-materials', this.productMaterials);
      this.$emit('material-selected-for-products', material.id);
    },
    updateMaterialCalculations({ index, updatePiecesPerMaterial = false, material }) {
      if (!material) return;

      const productQuantity = this.productQuantity || 1;
      const productWidth = parseFloat(this.productWidth) || 0;
      const productLength = parseFloat(this.productLength) || 0;

      // Add margins to product dimensions
      const effectiveProductWidth = productWidth + this.widthMargin;
      const effectiveProductLength = productLength + this.lengthMargin;

      let piecesPerMaterial = material.piecesPerMaterial || 1;

      if (updatePiecesPerMaterial && effectiveProductWidth > 0 && effectiveProductLength > 0) {
        const materialWidth = parseFloat(material.ancho) || 0;
        const materialLength = parseFloat(material.largo) || 0;

        if (materialWidth > 0 && materialLength > 0) {
          // Calculate how many pieces fit horizontally and vertically
          const horizontalPieces = Math.floor(materialWidth / effectiveProductWidth);
          const verticalPieces = Math.floor(materialLength / effectiveProductLength);

          // Try the other orientation as well
          const horizontalPiecesAlt = Math.floor(materialWidth / effectiveProductLength);
          const verticalPiecesAlt = Math.floor(materialLength / effectiveProductWidth);

          // Use the orientation that fits more pieces
          piecesPerMaterial = Math.max(
            horizontalPieces * verticalPieces,
            horizontalPiecesAlt * verticalPiecesAlt
          );
        }
      }

      // Calculate total sheets needed
      const totalSheets = piecesPerMaterial > 0 ? Math.ceil(productQuantity / piecesPerMaterial) : 0;

      // Calculate total square meters
      const materialWidth = parseFloat(material.ancho) || 0;
      const materialLength = parseFloat(material.largo) || 0;
      const totalSquareMeters = totalSheets * (materialWidth * materialLength) / 10000; // convert cm² to m²

      // Calculate total price
      const totalPrice = totalSquareMeters * (material.price || 0);

      // Update the material with new calculations
      const updatedMaterial = {
        ...material,
        piecesPerMaterial,
        totalSheets,
        totalSquareMeters,
        totalPrice
      };

      // Emit the calculation change event
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        totalSheets,
        totalSquareMeters,
        totalPrice,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });

      // Update the materials array
      const updatedMaterials = [...this.productMaterials];
      updatedMaterials[index] = updatedMaterial;
      this.$emit('update:product-materials', updatedMaterials);
    },
    calculatePiecesPerSheet(materialWidth, materialLength, productWidth, productLength, widthMargin, lengthMargin) {
      if (!materialWidth || !materialLength || !productWidth || !productLength) return 0;
      
      // Add margins to product dimensions
      const totalProductWidth = productWidth + widthMargin;
      const totalProductLength = productLength + lengthMargin;
      
      // Calculate how many pieces fit in each direction
      const piecesAcross = Math.floor(materialWidth / totalProductWidth);
      const piecesDown = Math.floor(materialLength / totalProductLength);
      
      // Try rotating the piece if it yields more pieces
      const piecesAcrossRotated = Math.floor(materialWidth / totalProductLength);
      const piecesDownRotated = Math.floor(materialLength / totalProductWidth);
      
      // Return the maximum number of pieces possible
      return Math.max(
        piecesAcross * piecesDown,
        piecesAcrossRotated * piecesDownRotated
      );
    },
    removeMaterial(index) {
      const removedMaterial = this.productMaterials[index];
      this.productMaterials.splice(index, 1);
      
      // Emit updates in the correct order
      this.$emit('update:product-materials', this.productMaterials);
      this.$emit('update:materials-cost', this.totalCost);
      this.$emit('material-calculation-changed', {
        materialId: removedMaterial.id,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    }
  },
  watch: {
    selectedMaterial(newValue) {
      this.$emit('material-selected-for-products', newValue);
    },
    comments(newValue) {
      this.globalComments = newValue;
    },
    productWidth() {
      // Recalculate all materials when product width changes
      this.productMaterials.forEach((_, index) => {
        this.updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material: this.productMaterials[index] });
      });
    },
    productLength() {
      // Recalculate all materials when product length changes
      this.productMaterials.forEach((_, index) => {
        this.updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material: this.productMaterials[index] });
      });
    }
  },
  mounted() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl);
    });
  }
};
</script>

<style scoped lang="scss">
.materials-tab {
  // Custom radio button styles for material selection
  .form-check-input[type="radio"] {
    &:checked {
      background-color: var(--cotalo-green);
      border-color: var(--cotalo-green);
    }

    &:focus {
      border-color: var(--cotalo-green);
      box-shadow: 0 0 0 0.25rem rgba(66, 185, 131, 0.25);
    }
  }

  .table {
    th, td {
      &:focus-within {
        border-color: var(--cotalo-green);
      }
    }
  }
  
  input {
    &:focus {
      border-color: var(--cotalo-green);
    }
  }
}
</style>