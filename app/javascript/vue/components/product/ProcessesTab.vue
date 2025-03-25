<template>
  <div class="processes-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-6 mb-3 mb-md-0 me-md-2">
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
      
      console.log('Adding process:', process);
      console.log('Base price:', basePrice);
      console.log('Product quantity:', this.productQuantity);
      
      // Check if we have selected material data
      if (this.selectedMaterialData) {
        console.log('Selected material:', this.selectedMaterialData);
        
        // Use the selected material's data for calculations
        const materialSheets = this.selectedMaterialData.totalSheets || 0;
        const materialSquareMeters = this.selectedMaterialData.totalSquareMeters || 0;
        
        console.log('Using selected material sheets:', materialSheets);
        console.log('Using selected material square meters:', materialSquareMeters);
        
        // Calculate price based on unit type
        if (process.unit === 'pieza') {
          // For pieces: quantity of products * process price
          calculatedPrice = basePrice * this.productQuantity;
          console.log('Calculated price for pieza:', calculatedPrice);
        } else if (process.unit === 'pliego') {
          // For sheets: use selected material's sheets * process price
          calculatedPrice = basePrice * materialSheets;
          console.log('Calculated price for pliego:', calculatedPrice, 'using', materialSheets, 'sheets from selected material');
        } else if (process.unit === 'mt2') {
          // For square meters: use selected material's square meters * process price
          calculatedPrice = basePrice * materialSquareMeters;
          console.log('Calculated price for mt2:', calculatedPrice, 'using exactly', materialSquareMeters, 'square meters from selected material');
        }
      } else {
        console.log('No selected material data, using totals from all materials');
        console.log('Total sheets:', this.totalSheets);
        console.log('Total square meters:', this.totalSquareMeters);
        
        // Calculate price based on unit type
        if (process.unit === 'pieza') {
          // For pieces: quantity of products * process price
          calculatedPrice = basePrice * this.productQuantity;
          console.log('Calculated price for pieza:', calculatedPrice);
        } else if (process.unit === 'pliego') {
          // For sheets: materials sheets * process price
          calculatedPrice = basePrice * this.totalSheets;
          console.log('Calculated price for pliego:', calculatedPrice, 'using', this.totalSheets, 'sheets');
        } else if (process.unit === 'mt2') {
          // For square meters: total square meters OF THE MATERIAL * process price
          calculatedPrice = basePrice * this.totalSquareMeters;
          console.log('Calculated price for mt2:', calculatedPrice, 'using exactly', this.totalSquareMeters, 'square meters');
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
      
      console.log('Added process, new total cost:', newTotalCost);
      
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
    // Method to recalculate all processes when quantity, sheets, or square meters change
    updateProcessCalculations() {
      console.log('[ProcessesTab] updateProcessCalculations called with:');
      console.log(`  Product Quantity: ${this.productQuantity}`);
      console.log(`  Total Sheets: ${this.totalSheets}`);
      console.log(`  Total Square Meters: ${this.totalSquareMeters}`);
      
      if (this.productProcesses.length === 0) {
        console.log('[ProcessesTab] No processes to recalculate');
        return;
      }
      
      console.log('[ProcessesTab] Recalculating for', this.productProcesses.length, 'processes');
      
      // Check if we have selected material data
      if (this.selectedMaterialData) {
        console.log('[ProcessesTab] Using selected material data for recalculation:', this.selectedMaterialData);
      }
      
      const updatedProcesses = this.productProcesses.map((process, index) => {
        console.log(`[ProcessesTab] Calculating process ${index + 1}: ${process.description} (unit: ${process.unit})`);
        
        // Skip processes that don't have the _needsRecalculation flag
        // This ensures we don't recalculate processes when selected material changes
        if (!process._needsRecalculation) {
          console.log(`[ProcessesTab] Process doesn't have recalculation flag, keeping original price: ${process.price}`);
          return process;
        }
        
        const basePrice = parseFloat(process.unitPrice) || 0;
        let calculatedPrice = basePrice;
        
        // Check if this process was tied to a specific material
        const useSelectedMaterial = process.selectedMaterialId === this.selectedMaterialId && this.selectedMaterialData;
        
        if (useSelectedMaterial) {
          console.log(`[ProcessesTab] Process was tied to selected material ID: ${process.selectedMaterialId}`);
          
          // Use the selected material's data for calculations
          const materialSheets = this.selectedMaterialData.totalSheets || 0;
          const materialSquareMeters = this.selectedMaterialData.totalSquareMeters || 0;
          
          // Recalculate price based on unit type
          if (process.unit === 'pieza') {
            calculatedPrice = basePrice * this.productQuantity;
            console.log(`  Pieza calculation: ${basePrice} × ${this.productQuantity} = ${calculatedPrice}`);
          } else if (process.unit === 'pliego') {
            calculatedPrice = basePrice * materialSheets;
            console.log(`  Pliego calculation: ${basePrice} × ${materialSheets} = ${calculatedPrice} (from selected material)`);
          } else if (process.unit === 'mt2') {
            calculatedPrice = basePrice * materialSquareMeters;
            console.log(`  mt2 calculation: ${basePrice} × ${materialSquareMeters} = ${calculatedPrice} (from selected material)`);
          } else {
            console.log(`  Standard unit: using base price ${basePrice}`);
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
            console.log(`  Pieza calculation: ${basePrice} × ${this.productQuantity} = ${calculatedPrice}`);
          } else if (process.unit === 'pliego') {
            calculatedPrice = basePrice * this.totalSheets;
            console.log(`  Pliego calculation: ${basePrice} × ${this.totalSheets} = ${calculatedPrice}`);
          } else if (process.unit === 'mt2') {
            calculatedPrice = basePrice * this.totalSquareMeters;
            console.log(`  mt2 calculation: ${basePrice} × ${this.totalSquareMeters} = ${calculatedPrice}`);
          } else {
            console.log(`  Standard unit: using base price ${basePrice}`);
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
      
      console.log('[ProcessesTab] Emitting updated processes with total cost:', newTotalCost);
      
      this.$emit('update:product-processes', updatedProcesses);
      this.$emit('update:processes-cost', newTotalCost);
    }
  },
  watch: {
    // Watch for changes in product quantity, sheets, or square meters
    productQuantity() {
      console.log('ProcessesTab: Product quantity changed to', this.productQuantity);
      this.updateProcessCalculations();
    },
    totalSheets() {
      console.log('ProcessesTab: Total sheets changed to', this.totalSheets);
      this.updateProcessCalculations();
    },
    totalSquareMeters() {
      console.log('ProcessesTab: Total square meters changed to', this.totalSquareMeters);
      this.updateProcessCalculations();
    },
    // Also watch for changes to processes array
    productProcesses: {
      handler(newProcesses) {
        console.log('ProcessesTab: Processes array changed, checking for recalculation flag');
        // Check if any processes have the recalculation flag
        const needsRecalculation = newProcesses.some(process => process._needsRecalculation);
        
        if (needsRecalculation) {
          console.log('ProcessesTab: Found processes needing recalculation');
          this.updateProcessCalculations();
        }
      },
      deep: true
    }
  },
  mounted() {
    console.log('ProcessesTab mounted with props:', {
      productProcesses: this.productProcesses,
      availableProcesses: this.availableProcesses,
      comments: this.comments,
      productQuantity: this.productQuantity,
      totalSheets: this.totalSheets,
      totalSquareMeters: this.totalSquareMeters,
      selectedMaterialId: this.selectedMaterialId,
      selectedMaterialData: this.selectedMaterialData
    });
    
    // Emit initial processes cost when component mounts
    const initialCost = this.productProcesses.reduce((sum, process) => {
      return sum + (parseFloat(process.price) || 0);
    }, 0);
    
    console.log('Emitting initial process cost:', initialCost);
    this.$emit('update:processes-cost', initialCost);
  }
}
</script>