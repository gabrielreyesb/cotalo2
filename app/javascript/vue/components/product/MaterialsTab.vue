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
                <input
                  type="radio"
                  :id="'material-radio-' + index"
                  :value="material.id"
                  v-model="selectedMaterialForProducts"
                  class="form-check-input me-2"
                  @change="selectMaterialForProducts(material.id)"
                />
                <button 
                  class="btn btn-sm btn-outline-primary me-1" 
                  @click="showMaterialVisualization(material)"
                  title="Visualizar disposición"
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

    <!-- Visualization Modal -->
    <div class="modal" :class="{'show': showVisualization}" tabindex="-1">
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              Disposición de Producto en Material: 
              <span class="material-title">{{ visualizationMaterial ? visualizationMaterial.description : '' }}</span>
            </h5>
            <button type="button" class="btn-close" @click="closeVisualization"></button>
          </div>
          <div class="modal-body">
            <canvas id="visualization-canvas" width="700" height="600"></canvas>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" @click="closeVisualization">Cerrar</button>
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
    },
    selectedMaterialId: {
      type: [Number, String],
      default: null
    }
  },
  data() {
    return {
      materialIdForAdd: '',
      globalComments: this.comments || '',
      selectedMaterialForProducts: this.selectedMaterialId,
      showVisualization: false,
      visualizationMaterial: null,
      canvasScale: 1
    }
  },
  computed: {
    canAdd() {
      return this.materialIdForAdd;
    },
    selectedMaterial() {
      if (!this.materialIdForAdd) return null;
      const material = this.availableMaterials.find(material => material.id === this.materialIdForAdd);
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
    handleKeyDown(event) {
      if (event.key === 'Escape' && this.showVisualization) {
        this.closeVisualization();
      }
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
      
      // Auto select the newly added material if no material is currently selected
      if (!this.selectedMaterialForProducts) {
        this.selectedMaterialForProducts = newMaterial.id;
        this.selectMaterialForProducts(newMaterial.id);
      }
      
      // Reset form
      this.materialIdForAdd = '';
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
    selectMaterialForProducts(materialId) {
      this.$emit('material-selected-for-products', materialId);
    },
    updateMaterialsCalculations() {
      // Recalculate values for all materials when product dimensions or quantity changes
      
      if (this.productMaterials.length > 0) {
        
        const updatedMaterials = this.productMaterials.map((material, index) => {
          
          // Deep clone to ensure we don't modify props directly
          const materialCopy = {
            ...material,
            ancho: material.ancho,
            largo: material.largo,
            price: material.price
          };
          
          const calculations = this.calculateMaterialValues(materialCopy);
          
          return {
            ...material,
            piecesPerMaterial: calculations.piecesPerMaterial,
            totalSheets: calculations.totalSheets,
            totalSquareMeters: calculations.totalSquareMeters,
            totalPrice: calculations.totalPrice,
            // Remove calculation flag
            _needsRecalculation: undefined
          };
        });
        
        const totalCost = updatedMaterials.reduce((sum, material) => {
          return sum + (parseFloat(material.totalPrice) || 0);
        }, 0);
        
        this.$emit('update:product-materials', updatedMaterials);
        this.$emit('update:materials-cost', totalCost);
      }
    },
    showMaterialVisualization(material) {
      this.visualizationMaterial = material;
      this.showVisualization = true;
      this.$nextTick(() => {
        this.drawVisualization();
      });
    },
    closeVisualization() {
      this.showVisualization = false;
      this.visualizationMaterial = null;
    },
    drawVisualization() {
      if (!this.visualizationMaterial || !this.productWidth || !this.productLength) return;
      
      const canvas = document.getElementById('visualization-canvas');
      if (!canvas) return;
      
      const ctx = canvas.getContext('2d');
      
      // Clear canvas
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      // Get dimensions
      const materialWidth = parseFloat(this.visualizationMaterial.ancho) || 0;
      const materialLength = parseFloat(this.visualizationMaterial.largo) || 0;
      const productWidth = this.productWidth;
      const productLength = this.productLength;
      
      // Calculate how many products fit in each direction
      let horizontalPieces, verticalPieces, useAlternateOrientation;
      
      // First orientation (width × length)
      const normalHorizontal = Math.floor(materialWidth / productWidth);
      const normalVertical = Math.floor(materialLength / productLength);
      const normalTotal = normalHorizontal * normalVertical;
      
      // Second orientation (length × width) - rotated 90 degrees
      const alternateHorizontal = Math.floor(materialWidth / productLength);
      const alternateVertical = Math.floor(materialLength / productWidth);
      const alternateTotal = alternateHorizontal * alternateVertical;
      
      // Use orientation that fits more pieces
      if (alternateTotal > normalTotal) {
        horizontalPieces = alternateHorizontal;
        verticalPieces = alternateVertical;
        useAlternateOrientation = true;
      } else {
        horizontalPieces = normalHorizontal;
        verticalPieces = normalVertical;
        useAlternateOrientation = false;
      }

      // Calculate piece dimensions based on orientation
      const pieceWidth = useAlternateOrientation ? productLength : productWidth;
      const pieceLength = useAlternateOrientation ? productWidth : productLength;
      
      // Calculate scaling factor to fit in canvas - leave space for info at top
      const infoHeight = 180; // Height reserved for information at the top
      const padding = 50; // Padding around the edges
      const maxCanvasWidth = canvas.width - 2 * padding;
      const maxCanvasHeight = canvas.height - 2 * padding - infoHeight;
      
      const widthScale = maxCanvasWidth / materialWidth;
      const heightScale = maxCanvasHeight / materialLength;
      
      // Use the smaller scale to ensure everything fits
      this.canvasScale = Math.min(widthScale, heightScale);
      
      // Calculate visual dimensions
      const scaledMaterialWidth = materialWidth * this.canvasScale;
      const scaledMaterialLength = materialLength * this.canvasScale;
      
      // Calculate starting position (centered horizontally, below info section)
      const startX = (canvas.width - scaledMaterialWidth) / 2;
      const startY = infoHeight + (canvas.height - infoHeight - scaledMaterialLength) / 2;
      
      // Draw information section with black background for better visibility
      ctx.fillStyle = '#1a1e21'; // Darker background for info area
      ctx.fillRect(0, 0, canvas.width, infoHeight);
      
      // Add information about the fit
      ctx.fillStyle = '#ffffff';
      ctx.font = '16px Arial';
      ctx.fillText(
        `Disposición óptima: ${horizontalPieces} × ${verticalPieces} = ${horizontalPieces * verticalPieces} piezas por material`,
        padding, 30
      );
      
      if (useAlternateOrientation) {
        ctx.fillText(`Orientación: Rotada (${productLength} × ${productWidth})`, padding, 60);
      } else {
        ctx.fillText(`Orientación: Normal (${productWidth} × ${productLength})`, padding, 60);
      }
      
      // Calculate wasted space percentage
      const materialArea = materialWidth * materialLength;
      const usedArea = horizontalPieces * verticalPieces * pieceWidth * pieceLength;
      const wastedArea = materialArea - usedArea;
      const wastedPercentage = (wastedArea / materialArea) * 100;
      
      ctx.fillText(
        `Área utilizada: ${usedArea.toFixed(2)} cm² (${(100 - wastedPercentage).toFixed(2)}%)`,
        padding, 90
      );
      
      // Product quantity information
      ctx.fillText(
        `Cantidad total requerida: ${this.productQuantity} piezas`,
        padding, 120
      );
      
      const sheetsNeeded = Math.ceil(this.productQuantity / (horizontalPieces * verticalPieces));
      ctx.fillText(
        `Materiales necesarios: ${sheetsNeeded} ${sheetsNeeded === 1 ? 'hoja' : 'hojas'}`,
        padding, 150
      );
      
      // Draw material outline
      ctx.strokeStyle = '#42b983'; // Green color to match theme
      ctx.lineWidth = 3;
      ctx.strokeRect(startX, startY, scaledMaterialWidth, scaledMaterialLength);
      
      // Add material dimensions as text
      ctx.font = '14px Arial';
      ctx.fillStyle = '#ffffff';
      ctx.textAlign = 'center';
      ctx.fillText(`${materialWidth} cm`, startX + scaledMaterialWidth / 2, startY - 10);
      
      ctx.textAlign = 'right';
      ctx.fillText(`${materialLength} cm`, startX - 10, startY + scaledMaterialLength / 2);
      ctx.textAlign = 'left'; // Reset alignment
      
      // Draw the product pieces
      ctx.strokeStyle = '#fff';
      ctx.lineWidth = 1;
      
      for (let i = 0; i < horizontalPieces; i++) {
        for (let j = 0; j < verticalPieces; j++) {
          const pieceX = startX + i * pieceWidth * this.canvasScale;
          const pieceY = startY + j * pieceLength * this.canvasScale;
          const scaledPieceWidth = pieceWidth * this.canvasScale;
          const scaledPieceLength = pieceLength * this.canvasScale;
          
          // Draw product rectangle
          ctx.strokeRect(pieceX, pieceY, scaledPieceWidth, scaledPieceLength);
          
          // Add piece number if there's enough space
          if (scaledPieceWidth > 30 && scaledPieceLength > 20) {
            ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
            ctx.textAlign = 'center';
            ctx.fillText(
              `${i * verticalPieces + j + 1}`, 
              pieceX + scaledPieceWidth / 2, 
              pieceY + scaledPieceLength / 2 + 5
            );
            ctx.textAlign = 'left'; // Reset alignment
          }
        }
      }
      
      // Highlight first piece (top-left)
      const examplePieceX = startX;
      const examplePieceY = startY;
      const scaledExampleWidth = pieceWidth * this.canvasScale;
      const scaledExampleLength = pieceLength * this.canvasScale;
      
      ctx.fillStyle = 'rgba(66, 185, 131, 0.7)'; // Green with transparency
      ctx.fillRect(examplePieceX, examplePieceY, scaledExampleWidth, scaledExampleLength);
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
    },
    // Also watch for changes to materials array
    productMaterials: {
      handler(newMaterials) {
        // Check if any materials have the recalculation flag
        const needsRecalculation = newMaterials.some(material => material._needsRecalculation);
        
        if (needsRecalculation) {
          this.updateMaterialsCalculations();
        }

        // Auto-select first material if none is selected and materials exist
        if (!this.selectedMaterialForProducts && newMaterials.length > 0) {
          this.selectedMaterialForProducts = newMaterials[0].id;
          this.selectMaterialForProducts(newMaterials[0].id);
        }
      },
      deep: true
    }
  },
  mounted() {    
    // Emit initial materials cost when component mounts
    this.$emit('update:materials-cost', this.totalCost);
    
    // Auto-select first material if none is selected and materials exist
    if (!this.selectedMaterialForProducts && this.productMaterials.length > 0) {
      this.selectedMaterialForProducts = this.productMaterials[0].id;
      this.selectMaterialForProducts(this.productMaterials[0].id);
    }

    // Add keyboard event for Escape to close modal
    document.addEventListener('keydown', this.handleKeyDown);
  },
  beforeDestroy() {
    // Clean up event listener
    document.removeEventListener('keydown', this.handleKeyDown);
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

/* Radio button styling */
.form-check-input {
  width: 1.25rem;
  height: 1.25rem;
  margin-top: 0.25rem;
  vertical-align: middle;
  cursor: pointer;
}

.form-check-input:checked {
  background-color: #42b983;
  border-color: #42b983;
}

/* Text colors */
.text-muted {
  color: #6c757d !important;
}

.text-end {
  text-align: right !important;
}

/* Visualization modal styles */
.modal {
  display: none;
  position: fixed;
  top: 0;
  left: 0;
  z-index: 1050;
  width: 100%;
  height: 100%;
  overflow: hidden;
  outline: 0;
  background-color: rgba(0, 0, 0, 0.5);
}

.modal.show {
  display: block;
}

.modal-dialog {
  position: relative;
  width: auto;
  margin: 0.5rem;
  pointer-events: none;
  max-width: 800px;
  margin: 1.75rem auto;
}

.modal-content {
  position: relative;
  display: flex;
  flex-direction: column;
  width: 100%;
  pointer-events: auto;
  background-color: #343a40;
  background-clip: padding-box;
  border: 1px solid rgba(0, 0, 0, 0.2);
  border-radius: 0.3rem;
  outline: 0;
}

.modal-header {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1rem;
  border-bottom: 1px solid #495057;
}

.modal-title {
  margin-bottom: 0;
  line-height: 1.5;
  color: #e9ecef;
}

.material-title {
  color: #42b983;
  font-weight: bold;
}

.modal-body {
  position: relative;
  flex: 1 1 auto;
  padding: 1rem;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #212529;
}

.modal-footer {
  display: flex;
  flex-wrap: wrap;
  flex-shrink: 0;
  align-items: center;
  justify-content: flex-end;
  padding: 0.75rem;
  border-top: 1px solid #495057;
}

.btn-close {
  box-sizing: content-box;
  width: 1em;
  height: 1em;
  padding: 0.25em 0.25em;
  color: #fff;
  background: transparent url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='%23fff'%3e%3cpath d='M.293.293a1 1 0 011.414 0L8 6.586 14.293.293a1 1 0 111.414 1.414L9.414 8l6.293 6.293a1 1 0 01-1.414 1.414L8 9.414l-6.293 6.293a1 1 0 01-1.414-1.414L6.586 8 .293 1.707a1 1 0 010-1.414z'/%3e%3c/svg%3e") center/1em auto no-repeat;
  border: 0;
  border-radius: 0.25rem;
  opacity: 0.5;
  cursor: pointer;
}

.btn-close:hover {
  opacity: 1;
}

#visualization-canvas {
  background-color: #212529;
  border: 1px solid #495057;
  border-radius: 4px;
  width: 700px;
  height: 600px;
}
</style>
