<template>
  <div class="materials-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-6">
              <label for="material-select" class="form-label">Seleccionar material</label>
              <select 
                id="material-select" 
                v-model="selectedMaterialId" 
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
            </div>
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary" 
                @click="addMaterial" 
                :disabled="!canAdd"
              >
                <i class="fa fa-plus me-1"></i> Agregar Material
              </button>
            </div>
          </div>
        </div>
      </div>

      <div v-if="!productMaterials.length" class="text-center my-5">
        <p class="text-muted">No hay materiales agregados. Selecciona un material y agrégalo al producto.</p>
      </div>

      <table v-else class="table table-dark table-striped">
        <thead>
          <tr>
            <th>Descripción</th>
            <th>Ancho</th>
            <th>Largo</th>
            <th>Precio</th>
            <th>Piezas por material</th>
            <th>Total hojas</th>
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
            <td class="text-center">{{ material.piecesPerMaterial }}</td>
            <td class="text-center">{{ material.totalSheets }}</td>
            <td class="text-center">{{ material.totalSquareMeters.toFixed(2) }} m²</td>
            <td class="text-end">{{ formatCurrency(material.totalPrice) }}</td>
            <td>
              <div class="btn-group">
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

      <!-- Global comments for all materials -->
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
    }
  },
  data() {
    return {
      selectedMaterialId: '',
      globalComments: this.comments || ''
    }
  },
  computed: {
    canAdd() {
      return this.selectedMaterialId;
    },
    selectedMaterial() {
      if (!this.selectedMaterialId) return null;
      const material = this.availableMaterials.find(material => material.id === this.selectedMaterialId);
      if (material) {
        console.log('Selected material:', material);
      }
      return material;
    },
    totalCost() {
      return this.productMaterials.reduce((sum, material) => {
        return sum + (parseFloat(material.totalPrice) || 0);
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
    calculateMaterialValues(material) {
      const productWidth = this.productWidth;
      const productLength = this.productLength;
      const materialWidth = parseFloat(material.ancho) || 0;
      const materialLength = parseFloat(material.largo) || 0;
      const quantity = this.productQuantity;
      
      // Calculate how many pieces can fit in one material sheet
      let piecesPerMaterial = 0;
      if (materialWidth > 0 && materialLength > 0 && productWidth > 0 && productLength > 0) {
        // Calculate how many pieces fit horizontally and vertically
        const horizontalPieces = Math.floor(materialWidth / productWidth);
        const verticalPieces = Math.floor(materialLength / productLength);
        
        // Try the other orientation as well
        const horizontalPiecesAlt = Math.floor(materialWidth / productLength);
        const verticalPiecesAlt = Math.floor(materialLength / productWidth);
        
        // Use the orientation that fits more pieces
        piecesPerMaterial = Math.max(
          horizontalPieces * verticalPieces, 
          horizontalPiecesAlt * verticalPiecesAlt
        );
      }
      
      // Calculate total sheets needed
      const totalSheets = piecesPerMaterial > 0 ? Math.ceil(quantity / piecesPerMaterial) : 0;
      
      // Calculate total square meters
      const totalSquareMeters = totalSheets * (materialWidth * materialLength) / 10000; // convert cm² to m²
      
      // Calculate total price - based on square meters, not sheets
      const totalPrice = totalSquareMeters * material.price;
      
      return {
        piecesPerMaterial,
        totalSheets,
        totalSquareMeters,
        totalPrice
      };
    },
    addMaterial() {
      if (!this.canAdd || !this.selectedMaterial) return;
      
      const material = this.selectedMaterial;
      const calculations = this.calculateMaterialValues(material);
      
      const newMaterial = {
        id: material.id,
        description: material.description,
        ancho: material.ancho || 0,
        largo: material.largo || 0,
        price: material.price || 0,
        piecesPerMaterial: calculations.piecesPerMaterial,
        totalSheets: calculations.totalSheets,
        totalSquareMeters: calculations.totalSquareMeters,
        totalPrice: calculations.totalPrice
      };
      
      const updatedMaterials = [...this.productMaterials, newMaterial];
      this.$emit('update:product-materials', updatedMaterials);
      
      // Emit the total cost of materials
      this.$emit('update:materials-cost', this.totalCost + (parseFloat(newMaterial.totalPrice) || 0));
      
      // Reset form
      this.selectedMaterialId = '';
    },
    removeMaterial(index) {
      if (confirm('¿Estás seguro de que quieres eliminar este material?')) {
        const materialToRemove = this.productMaterials[index];
        const updatedMaterials = [...this.productMaterials];
        updatedMaterials.splice(index, 1);
        
        this.$emit('update:product-materials', updatedMaterials);
        
        // Calculate and emit the new total cost
        const newTotalCost = this.totalCost - (parseFloat(materialToRemove.totalPrice) || 0);
        this.$emit('update:materials-cost', newTotalCost);
      }
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    },
    updateMaterialsCalculations() {
      // Recalculate values for all materials when product dimensions or quantity changes
      if (this.productMaterials.length > 0) {
        const updatedMaterials = this.productMaterials.map(material => {
          const calculations = this.calculateMaterialValues({
            ...material,
            ancho: material.ancho,
            largo: material.largo,
            price: material.price
          });
          
          return {
            ...material,
            piecesPerMaterial: calculations.piecesPerMaterial,
            totalSheets: calculations.totalSheets,
            totalSquareMeters: calculations.totalSquareMeters,
            totalPrice: calculations.totalPrice
          };
        });
        
        this.$emit('update:product-materials', updatedMaterials);
        this.$emit('update:materials-cost', updatedMaterials.reduce((sum, material) => {
          return sum + (parseFloat(material.totalPrice) || 0);
        }, 0));
      }
    }
  },
  watch: {
    productWidth() {
      this.updateMaterialsCalculations();
    },
    productLength() {
      this.updateMaterialsCalculations();
    },
    productQuantity() {
      this.updateMaterialsCalculations();
    }
  },
  mounted() {
    console.log('MaterialsTab mounted with props:', {
      productMaterials: this.productMaterials,
      availableMaterials: this.availableMaterials,
      comments: this.comments,
      productWidth: this.productWidth,
      productLength: this.productLength,
      productQuantity: this.productQuantity
    });
    
    // Emit initial materials cost when component mounts
    this.$emit('update:materials-cost', this.totalCost);
  }
}
</script>

<style scoped>
.materials-tab {
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

/* No materials message styling */
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
