<template>
  <div class="processes-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-9 mb-3 mb-md-0">
              <div class="d-flex align-items-center">
                <label for="process-select" class="form-label mb-0 me-2">Seleccionar proceso</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  title="<strong>Cómo se calculan los costos:</strong><br>
                  • <u>Pieza</u>: precio de proceso × cantidad de piezas de producto<br>
                  • <u>Pliego</u>: precio de proceso × total de pliegos de material<br>
                  • <u>Metro cuadrado</u>: precio de proceso × total de metros cuadrados de material"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
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
              <div v-if="validationMessage" class="text-danger mt-2">
                {{ validationMessage }}
              </div>
            </div>

            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary" 
                @click="addProcess" 
                :disabled="!canAdd"
                :title="validationMessage"
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

      <!-- Table view for medium and large screens -->
      <div v-if="productProcesses.length" class="d-none d-md-block">
        <table class="table table-dark table-striped">
          <thead>
            <tr>
              <th>Descripción</th>
              <th>Unidad</th>
              <th>Aplicado a material</th>
              <th>Precio por Unidad</th>
              <th>Precio Total</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(process, index) in productProcesses" :key="index">
              <td>{{ process.description }}</td>
              <td>{{ process.unit }}</td>
              <td>{{ process.materialDescription || 'No especificado' }}</td>
              <td class="text-end">
                <input 
                  type="number" 
                  class="form-control form-control-sm" 
                  v-model.number="process.unitPrice" 
                  min="0"
                  step="0.01"
                  @change="updateProcessUnitPrice(index)"
                  title="Puedes editar este valor manualmente para ajustar el precio por unidad"
                  data-toggle="tooltip"
                />
              </td>
              <td class="text-end">{{ formatCurrency(process.price) }}</td>
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
              <th colspan="4" class="text-end">Total:</th>
              <th class="text-end">{{ formatCurrency(totalCost) }}</th>
              <th></th>
            </tr>
          </tfoot>
        </table>
      </div>

      <!-- Card view for small screens -->
      <div v-if="productProcesses.length" class="d-md-none">
        <div v-for="(process, index) in productProcesses" :key="index" class="card mb-3 shadow-sm">
          <div class="card-body p-2">
            <!-- First row: Process description only -->
            <h6 class="card-title mb-2">{{ process.description }}</h6>
            
            <!-- Second row: Unit, material, process price -->
            <div class="row g-2 mb-2">
              <div class="col-4">
                <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                  {{ process.unit }}
                </div>
              </div>
              <div class="col-4">
                <div class="badge bg-dark d-block text-center p-2 w-100 material-badge text-truncate">
                  {{ process.materialDescription || 'No especificado' }}
                </div>
              </div>
              <div class="col-4">
                <input 
                  type="number" 
                  class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                  v-model.number="process.unitPrice" 
                  min="0"
                  step="0.01"
                  @change="updateProcessUnitPrice(index)"
                  title="Haz clic para editar el precio unitario"
                />
              </div>
            </div>
            
            <!-- Third row: Total price and delete button -->
            <div class="d-flex justify-content-between align-items-center">
              <span class="badge bg-success fs-5">{{ formatCurrency(process.price) }}</span>
              <button 
                class="btn btn-sm btn-outline-danger px-2 py-1" 
                @click="removeProcess(index)"
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
              <span class="fw-bold">Total procesos:</span>
              <span class="fs-5">{{ formatCurrency(totalCost) }}</span>
            </div>
          </div>
        </div>
      </div>

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
    productWidth: {
      type: Number,
      default: 0
    },
    productLength: {
      type: Number,
      default: 0
    },
    totalSheets: {
      type: Number,
      default: 0
    },
    totalSquareMeters: {
      type: Number,
      default: 0
    },
    selectedMaterialId: {
      type: [Number, String],
      default: null
    },
    selectedMaterialData: {
      type: Object,
      default: () => null
    },
    productMaterials: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      selectedProcessId: '',
      globalComments: this.comments || '',
      validationMessage: ''
    }
  },
  computed: {
    canAdd() {
      if (!this.selectedProcessId) {
        this.validationMessage = '';
        return false;
      }

      const process = this.selectedProcess;
      if (!process) return false;

      // First validate that there is at least one material
      if (!this.productMaterials || this.productMaterials.length === 0) {
        this.validationMessage = 'Primero debes agregar al menos un material en la pestaña de materiales';
        return false;
      }

      // Then validate based on process unit type
      if (process.unit === 'mt2' || process.unit === 'pliego') {
        // No additional validation needed for m2 and pliego units since we already checked for materials
        this.validationMessage = '';
        return true;
      } else if (process.unit === 'pieza') {
        // For pieza unit, validate product dimensions and quantity
        if (!this.productQuantity || this.productQuantity <= 0) {
          this.validationMessage = 'Por favor, especifica la cantidad de piezas del producto en la pestaña de información general';
          return false;
        }
        if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
          this.validationMessage = 'Por favor, especifica el ancho y largo del producto en la pestaña de información general';
          return false;
        }
      }

      this.validationMessage = '';
      return true;
    },
    selectedProcess() {
      if (!this.selectedProcessId) return null;
      const process = this.availableProcesses.find(process => process.id === this.selectedProcessId);
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
            
      // Check if we have selected material data
      if (this.selectedMaterialData) {
        
        // Use the selected material's data for calculations
        const materialSheets = this.selectedMaterialData.totalSheets || 0;
        const materialSquareMeters = this.selectedMaterialData.totalSquareMeters || 0;
        
        // Calculate price based on unit type
        if (process.unit === 'pieza') {
          // For pieces: quantity of products * process price
          calculatedPrice = basePrice * this.productQuantity;
        } else if (process.unit === 'pliego') {
          // For sheets: use selected material's sheets * process price
          calculatedPrice = basePrice * materialSheets;
        } else if (process.unit === 'mt2') {
          // For square meters: use selected material's square meters * process price
          calculatedPrice = basePrice * materialSquareMeters;
        }
      } else {

        // Calculate price based on unit type
        if (process.unit === 'pieza') {
          // For pieces: quantity of products * process price
          calculatedPrice = basePrice * this.productQuantity;
        } else if (process.unit === 'pliego') {
          // For sheets: materials sheets * process price
          calculatedPrice = basePrice * this.totalSheets;
        } else if (process.unit === 'mt2') {
          // For square meters: total square meters OF THE MATERIAL * process price
          calculatedPrice = basePrice * this.totalSquareMeters;
        }
      }
      
      const newProcess = {
        id: process.id,
        description: process.description,
        unit: process.unit || 'unidad',
        unitPrice: basePrice, // Store the original unit price
        price: calculatedPrice, // Store the calculated total price
        selectedMaterialId: this.selectedMaterialId, // Store the material ID used for calculation
        materialDescription: this.selectedMaterialData ? this.selectedMaterialData.description : null
      };
      
      const updatedProcesses = [...this.productProcesses, newProcess];
      this.$emit('update:product-processes', updatedProcesses);
      
      // Calculate the new total cost including the new process
      const newTotalCost = this.totalCost + calculatedPrice;
      
      // Emit the updated total cost of processes
      this.$emit('update:processes-cost', newTotalCost);
      
      // Reset form
      this.selectedProcessId = '';
    },
    removeProcess(index) {
      const processToRemove = this.productProcesses[index];
      const updatedProcesses = [...this.productProcesses];
      updatedProcesses.splice(index, 1);
      
      this.$emit('update:product-processes', updatedProcesses);
      
      // Calculate and emit the new total cost
      const newTotalCost = this.totalCost - (parseFloat(processToRemove.price) || 0);
      this.$emit('update:processes-cost', newTotalCost);
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    },
    updateProcessUnitPrice(index) {
      if (index < 0 || index >= this.productProcesses.length) return;
      
      const process = this.productProcesses[index];
      const basePrice = parseFloat(process.unitPrice) || 0;
      let calculatedPrice = basePrice;
      
      // Check if this process was tied to a specific material
      const useSelectedMaterial = process.selectedMaterialId === this.selectedMaterialId && this.selectedMaterialData;
      
      if (useSelectedMaterial) {
        // Use the selected material's data for calculations
        const materialSheets = this.selectedMaterialData.totalSheets || 0;
        const materialSquareMeters = this.selectedMaterialData.totalSquareMeters || 0;
        
        // Recalculate price based on unit type
        if (process.unit === 'pieza') {
          calculatedPrice = basePrice * this.productQuantity;
        } else if (process.unit === 'pliego') {
          calculatedPrice = basePrice * materialSheets;
        } else if (process.unit === 'mt2') {
          calculatedPrice = basePrice * materialSquareMeters;
        }
      } else {
        // Use total values from all materials
        // Recalculate price based on unit type
        if (process.unit === 'pieza') {
          calculatedPrice = basePrice * this.productQuantity;
        } else if (process.unit === 'pliego') {
          calculatedPrice = basePrice * this.totalSheets;
        } else if (process.unit === 'mt2') {
          calculatedPrice = basePrice * this.totalSquareMeters;
        }
      }
      
      // Create a copy of the processes array
      const updatedProcesses = [...this.productProcesses];
      
      // Update the specific process with the new calculated price
      updatedProcesses[index] = {
        ...process,
        price: calculatedPrice
      };
      
      // Calculate new total cost
      const newTotalCost = updatedProcesses.reduce((sum, process) => {
        return sum + (parseFloat(process.price) || 0);
      }, 0);
      
      // Emit updated processes and cost
      this.$emit('update:product-processes', updatedProcesses);
      this.$emit('update:processes-cost', newTotalCost);
    },
    updateProcessCalculations() {      
      if (this.productProcesses.length === 0) {
        return;
      }
      
      const updatedProcesses = this.productProcesses.map((process, index) => {
        // Skip processes that don't have the _needsRecalculation flag
        // This ensures we don't recalculate processes when selected material changes
        if (!process._needsRecalculation) {
          return process;
        }
        
        const basePrice = parseFloat(process.unitPrice) || 0;
        let calculatedPrice = basePrice;
        
        // Check if this process was tied to a specific material
        const useSelectedMaterial = process.selectedMaterialId === this.selectedMaterialId && this.selectedMaterialData;
        
        if (useSelectedMaterial) {
          
          // Use the selected material's data for calculations
          const materialSheets = this.selectedMaterialData.totalSheets || 0;
          const materialSquareMeters = this.selectedMaterialData.totalSquareMeters || 0;
          
          // Recalculate price based on unit type
          if (process.unit === 'pieza') {
            calculatedPrice = basePrice * this.productQuantity;
          } else if (process.unit === 'pliego') {
            calculatedPrice = basePrice * materialSheets;
          } else if (process.unit === 'mt2') {
            calculatedPrice = basePrice * materialSquareMeters;
          } else {
            calculatedPrice = basePrice;
          }
          
          // Update material description if it's not already set and we have selected material data
          if (!process.materialDescription && this.selectedMaterialData) {
            process.materialDescription = this.selectedMaterialData.description;
          }
        } else {
          // Use total values from all materials
          // Recalculate price based on unit type
          if (process.unit === 'pieza') {
            calculatedPrice = basePrice * this.productQuantity;
          } else if (process.unit === 'pliego') {
            calculatedPrice = basePrice * this.totalSheets;
          } else if (process.unit === 'mt2') {
            calculatedPrice = basePrice * this.totalSquareMeters;
          } else {
            calculatedPrice = basePrice;
          }
        }
        
        return {
          ...process,
          price: calculatedPrice,
          // Remove calculation flag
          _needsRecalculation: undefined
        };
      });
      
      // Calculate and emit the new total cost
      const newTotalCost = updatedProcesses.reduce((sum, process) => {
        return sum + (parseFloat(process.price) || 0);
      }, 0);
      
      this.$emit('update:product-processes', updatedProcesses);
      this.$emit('update:processes-cost', newTotalCost);
    }
  },
  watch: {
    // Watch for changes in product quantity, sheets, or square meters
    productQuantity() {
      this.updateProcessCalculations();
    },
    totalSheets() {
      this.updateProcessCalculations();
    },
    totalSquareMeters() {
      this.updateProcessCalculations();
    },
    // Also watch for changes to processes array
    productProcesses: {
      handler(newProcesses) {
        // Check if any processes have the recalculation flag
        const needsRecalculation = newProcesses.some(process => process._needsRecalculation);
        
        if (needsRecalculation) {
          this.updateProcessCalculations();
        }
      },
      deep: true
    }
  },
  mounted() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Emit initial processes cost when component mounts
    const initialCost = this.productProcesses.reduce((sum, process) => {
      return sum + (parseFloat(process.price) || 0);
    }, 0);
    
    this.$emit('update:processes-cost', initialCost);
  }
}
</script>