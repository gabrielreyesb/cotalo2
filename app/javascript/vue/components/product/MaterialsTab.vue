<template>
  <div class="materials-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <!-- Section 1: Material Selection/Add (already inside) -->
          <div class="row align-items-end">
            <!-- Material selection -->
            <div class="col-md-9 mb-3 mb-md-0">
              <label for="material-select" class="form-label">Seleccionar material</label>
              <select 
                id="material-select" 
                v-model="materialIdForAdd" 
                class="form-select"
                :disabled="!availableMaterials.length"
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
            <!-- Add material button -->
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary" 
                @click="addMaterial" 
                :disabled="!canAdd"
                :title="validationMessage"
              >
                <i class="fa fa-plus me-1"></i> Agregar Material
              </button>
            </div>
          </div>
          
          <!-- Section 2: No materials message -->
          <div v-if="!productMaterials.length" class="text-center my-5">
            <p class="text-muted">No hay materiales agregados. Selecciona un material y agrégalo al producto.</p>
          </div>

          <!-- Section 3 & 4: Materials table (Desktop) & Cards (Mobile) Container -->
          <div v-if="productMaterials.length" class="mt-4">
            <!-- Desktop Table -->
            <div class="d-none d-md-block">
              <table class="table table-dark table-striped">
                <thead>
                  <tr>
                    <th>Descripción</th>
                    <th>Ancho</th>
                    <th>Largo</th>
                    <th>Precio</th>
                    <th>Piezas por material</th>
                    <th>Total pliegos</th>
                    <th>Total m²</th>
                    <th>Precio total</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(material, index) in productMaterials" :key="index">
                    <td>{{ material.description }}</td>
                    <td>{{ material.ancho }} cm</td>
                    <td>{{ material.largo }} cm</td>
                    <td class="text-end">{{ formatCurrency(material.price) }}</td>
                    <td class="text-center">
                      <input 
                        type="number" 
                        class="form-control form-control-sm" 
                        v-model.number="material.piecesPerMaterial" 
                        min="1"
                        @change="updateMaterialCalculations(index)"
                        title="Puedes editar este valor manualmente para ajustar la cantidad de piezas por material"
                        data-toggle="tooltip"
                      />
                    </td>
                    <td class="text-center">{{ material.totalSheets }}</td>
                    <td class="text-center">{{ material.totalSquareMeters.toFixed(2) }} m²</td>
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
                          class="btn btn-sm btn-outline-info" 
                          @click="showMaterialVisualization(material)"
                          title="Visualizar material"
                        >
                          <i class="fa fa-eye"></i>
                        </button>
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
                      <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                        {{ material.ancho }} cm
                      </div>
                    </div>
                    <div class="col-4">
                      <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                        {{ material.largo }} cm
                      </div>
                    </div>
                    <div class="col-4">
                      <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                        {{ formatCurrency(material.price) }}
                      </div>
                    </div>
                  </div>
                  <!-- Third row: Pieces per material, total sheets, total m2 -->
                  <div class="row g-2 mb-2">
                    <div class="col-4">
                      <input 
                        type="number" 
                        class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                        v-model.number="material.piecesPerMaterial" 
                        min="1"
                        @change="updateMaterialCalculations(index)"
                        title="Haz clic para editar la cantidad de piezas por material"
                      />
                    </div>
                    <div class="col-4">
                      <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                        {{ material.totalSheets }} pgs
                      </div>
                    </div>
                    <div class="col-4">
                      <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                        {{ material.totalSquareMeters.toFixed(1) }} m²
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
                        class="btn btn-sm btn-outline-info" 
                        @click="showMaterialVisualization(material)"
                      >
                        <i class="fa fa-eye"></i>
                      </button>
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

          <!-- Section 5: Comments -->
          <div class="card mt-3"> <!-- This is another card, maybe just use a form-group? -->
             <div class="card-body"> <!-- Let's remove this nested card structure for comments -->
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
          
          <!-- Section 6: Manual material form button and form -->
          <div class="mt-3">
            <button 
              class="btn btn-sm btn-outline-secondary mb-2" 
              @click="showCustomMaterialForm = !showCustomMaterialForm"
            >
              <i class="fa" :class="showCustomMaterialForm ? 'fa-minus' : 'fa-plus'"></i>
              {{ showCustomMaterialForm ? 'Ocultar' : 'Agregar material manualmente' }}
            </button>
            
            <div v-if="showCustomMaterialForm">
              <!-- Using another card here might be okay for visual separation, or remove it too -->
              <div class="card mb-3"> 
                <div class="card-body">
                    <h6 class="mb-3">Agregar material manualmente</h6>
                    <div class="mb-3">
                      <label for="custom-material-description" class="form-label">Descripción</label>
                      <input 
                        type="text" 
                        class="form-control" 
                        id="custom-material-description" 
                        v-model="customMaterial.description"
                      />
                    </div>
                    <div class="row">
                      <div class="col-md-4 mb-3">
                        <label for="custom-material-width" class="form-label">Ancho (cm)</label>
                        <input 
                          type="number" 
                          class="form-control" 
                          id="custom-material-width" 
                          v-model.number="customMaterial.ancho" 
                          min="0"
                          step="0.1"
                        />
                      </div>
                      <div class="col-md-4 mb-3">
                        <label for="custom-material-length" class="form-label">Largo (cm)</label>
                        <input 
                          type="number" 
                          class="form-control" 
                          id="custom-material-length" 
                          v-model.number="customMaterial.largo" 
                          min="0"
                          step="0.1"
                        />
                      </div>
                      <div class="col-md-4 mb-3">
                        <label for="custom-material-price" class="form-label">Precio</label>
                        <input 
                          type="number" 
                          class="form-control" 
                          id="custom-material-price" 
                          v-model.number="customMaterial.price" 
                          min="0"
                          step="0.01"
                        />
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-md-12 d-grid">
                        <button 
                          class="btn btn-success" 
                          @click="addCustomMaterial"
                          :disabled="!canAddCustomMaterial"
                        >
                          <i class="fa fa-plus me-1"></i> Agregar material manualmente
                        </button>
                      </div>
                    </div>
                </div>
              </div>
            </div>
          </div>

          <!-- END MOVED SECTIONS -->
        </div> <!-- Close main card-body -->
      </div> <!-- Close main card -->

      <!-- Section 7: Visualization Panel (Keep outside the main card) -->
      <material-visualization-panel
        :is-open="showVisualization"
        :material="selectedMaterialForVisualization"
        :product-width="productWidth"
        :product-length="productLength"
        :width-margin="widthMargin"
        :length-margin="lengthMargin"
        @close="closeVisualization"
      />
      
    </div> <!-- Close green-accent-panel -->
  </div> <!-- Close materials-tab -->
</template>

<script>
import MaterialVisualizationPanel from './MaterialVisualizationPanel.vue'

export default {
  name: 'MaterialsTab',
  components: {
    MaterialVisualizationPanel
  },
  props: {
    productMaterials: {
      type: Array,
      default: () => []
    },
    availableMaterials: {
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
    productWidth: {
      type: Number,
      default: 0
    },
    productLength: {
      type: Number,
      default: 0
    },
    widthMargin: {
      type: Number,
      default: 0
    },
    lengthMargin: {
      type: Number,
      default: 0
    },
    selectedMaterialId: {
      type: [Number, String],
      default: null
    }
  },
  data() {
    return {
      materialIdForAdd: '',
      showCustomMaterialForm: false,
      showVisualization: false,
      selectedMaterialForVisualization: null,
      customMaterial: {
        description: '',
        ancho: null,
        largo: null,
        price: null
      },
      globalComments: this.comments || '',
      validationMessage: ''
    }
  },
  computed: {
    canAdd() {
      // Only validate if a material is selected
      if (!this.materialIdForAdd) {
        this.validationMessage = '';
        return false;
      }

      // Check if any required information is missing
      if (!this.productQuantity || this.productQuantity <= 0 ||
          !this.productWidth || this.productWidth <= 0 ||
          !this.productLength || this.productLength <= 0) {
        this.validationMessage = 'Por favor, completa la información del producto en la pestaña de información general';
        return false;
      }

      // Clear validation message if all checks pass
      this.validationMessage = '';
      return true;
    },
    totalCost() {
      return this.productMaterials.reduce((sum, material) => sum + (material.totalPrice || 0), 0);
    },
    canAddCustomMaterial() {
      return this.customMaterial.description &&
             this.customMaterial.ancho > 0 &&
             this.customMaterial.largo > 0 &&
             this.customMaterial.price > 0;
    },
    selectedMaterial: {
      get() {
        return this.selectedMaterialId;
      },
      set(value) {
        // If trying to deselect a material, prevent it
        if (!value && this.productMaterials.length > 0) {
          return;
        }
        this.$emit('material-selected-for-products', value);
      }
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
    },
    addMaterial() {
      const material = this.availableMaterials.find(m => m.id === this.materialIdForAdd);
      if (!material) return;

      // Calculate how many pieces fit in the material sheet
      const materialWidth = parseFloat(material.ancho) || 0;
      const materialLength = parseFloat(material.largo) || 0;
      
      // Add margins to product dimensions
      const effectiveProductWidth = this.productWidth + this.widthMargin;
      const effectiveProductLength = this.productLength + this.lengthMargin;

      // Calculate pieces that fit in both orientations
      const horizontalPieces = Math.floor(materialWidth / effectiveProductWidth);
      const verticalPieces = Math.floor(materialLength / effectiveProductLength);
      
      // Try the other orientation as well
      const horizontalPiecesAlt = Math.floor(materialWidth / effectiveProductLength);
      const verticalPiecesAlt = Math.floor(materialLength / effectiveProductWidth);
      
      // Use the orientation that fits more pieces
      const piecesPerMaterial = Math.max(
        horizontalPieces * verticalPieces,
        horizontalPiecesAlt * verticalPiecesAlt
      );
      
      // Calculate total sheets needed based on pieces per material
      const totalSheets = Math.ceil(this.productQuantity / piecesPerMaterial);
      
      // Calculate total square meters
      const totalSquareMeters = (materialWidth * materialLength * totalSheets) / 10000; // convert to m²
      
      // Calculate total price based on square meters
      const totalPrice = material.price * totalSquareMeters;
      
      const newMaterial = {
        ...material,
        piecesPerMaterial,
        totalSheets,
        totalSquareMeters,
        totalPrice
      };

      // Add the new material to the existing materials
      const updatedMaterials = [...this.productMaterials, newMaterial];
      this.$emit('update:product-materials', updatedMaterials);
      this.$emit('update:materials-cost', this.calculateTotalCost(updatedMaterials));
      
      // If this is the first material or no material is currently selected, select it
      if (this.productMaterials.length === 0) {
        this.$emit('material-selected-for-products', newMaterial.id);
      }
      
      this.materialIdForAdd = '';
    },
    updateMaterialCalculations(index) {
      const material = this.productMaterials[index];
      if (!material || material.piecesPerMaterial <= 0) return;

      // Calculate total sheets needed based on pieces per material
      const totalSheets = Math.ceil(this.productQuantity / material.piecesPerMaterial);

      // Calculate total square meters
      const totalSquareMeters = (material.ancho * material.largo * totalSheets) / 10000;

      // Calculate total price based on square meters
      const totalPrice = material.price * totalSquareMeters;

      const updatedMaterial = {
        ...material,
        totalSheets,
        totalSquareMeters,
        totalPrice
      };
      
      // Update the material in the array
      const updatedMaterials = [...this.productMaterials];
      updatedMaterials[index] = updatedMaterial;
      
      this.$emit('update:product-materials', updatedMaterials);
      this.$emit('update:materials-cost', this.calculateTotalCost(updatedMaterials));
      this.$emit('material-calculation-changed', { index, material: updatedMaterial });
    },
    removeMaterial(index) {
      // Store the ID of the material being removed
      const removedMaterialId = this.productMaterials[index].id;
      
      // Remove the material
      const updatedMaterials = this.productMaterials.filter((_, i) => i !== index);
      
      // Update materials and cost
      this.$emit('update:product-materials', updatedMaterials);
      this.$emit('update:materials-cost', this.calculateTotalCost(updatedMaterials));

      // If we removed the selected material and there are other materials, select the first one
      if (removedMaterialId === this.selectedMaterialId && updatedMaterials.length > 0) {
        this.$emit('material-selected-for-products', updatedMaterials[0].id);
      }
    },
    calculateTotalCost(materials) {
      return materials.reduce((sum, material) => sum + (material.totalPrice || 0), 0);
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    },
    addCustomMaterial() {
      if (!this.canAddCustomMaterial) return;

      // Calculate how many pieces fit in the material sheet
      const materialWidth = parseFloat(this.customMaterial.ancho) || 0;
      const materialLength = parseFloat(this.customMaterial.largo) || 0;
      
      // Add margins to product dimensions
      const effectiveProductWidth = this.productWidth + this.widthMargin;
      const effectiveProductLength = this.productLength + this.lengthMargin;

      // Calculate pieces that fit in both orientations
      const horizontalPieces = Math.floor(materialWidth / effectiveProductWidth);
      const verticalPieces = Math.floor(materialLength / effectiveProductLength);
      
      // Try the other orientation as well
      const horizontalPiecesAlt = Math.floor(materialWidth / effectiveProductLength);
      const verticalPiecesAlt = Math.floor(materialLength / effectiveProductWidth);
      
      // Use the orientation that fits more pieces
      const piecesPerMaterial = Math.max(
        horizontalPieces * verticalPieces,
        horizontalPiecesAlt * verticalPiecesAlt
      );

      // Calculate total sheets needed based on pieces per material
      const totalSheets = Math.ceil(this.productQuantity / piecesPerMaterial);

      // Calculate total square meters
      const totalSquareMeters = (materialWidth * materialLength * totalSheets) / 10000; // convert to m²

      // Calculate total price based on square meters
      const totalPrice = this.customMaterial.price * totalSquareMeters;

      const newMaterial = {
        id: Date.now(), // Temporary ID for custom materials
        description: this.customMaterial.description,
        ancho: materialWidth,
        largo: materialLength,
        price: this.customMaterial.price,
        piecesPerMaterial,
        totalSheets,
        totalSquareMeters,
        totalPrice
      };

      // Add the new material to the existing materials
      const updatedMaterials = [...this.productMaterials, newMaterial];
      this.$emit('update:product-materials', updatedMaterials);
      this.$emit('update:materials-cost', this.calculateTotalCost(updatedMaterials));
      
      // If this is the first material or no material is currently selected, select it
      if (this.productMaterials.length === 0) {
        this.$emit('material-selected-for-products', newMaterial.id);
      }
      
      // Reset form
      this.customMaterial = {
        description: '',
        ancho: null,
        largo: null,
        price: null
      };
      this.showCustomMaterialForm = false;
    },
    showMaterialVisualization(material) {
      this.selectedMaterialForVisualization = material;
      this.showVisualization = true;
    },
    closeVisualization() {
      this.showVisualization = false;
      this.selectedMaterialForVisualization = null;
    }
  },
  watch: {
    comments: {
      handler(newComments) {
        this.globalComments = newComments;
      },
      immediate: true
    },
    productMaterials: {
      handler(newMaterials) {
        // If there are materials but none selected, select the first one
        if (newMaterials.length > 0 && !this.selectedMaterialId) {
          this.$emit('material-selected-for-products', newMaterials[0].id);
        }
      },
      immediate: true
    }
  }
}
</script>

<style scoped>
.form-check-input:checked {
  background-color: #198754;
  border-color: #198754;
}

.form-check-input:focus {
  border-color: #198754;
  box-shadow: 0 0 0 0.25rem rgba(25, 135, 84, 0.25);
}
</style>