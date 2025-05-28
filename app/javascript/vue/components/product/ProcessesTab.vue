<template>
  <div class="processes-tab">
    <div v-if="validationMessage" class="processes-validation-message mt-2">
      {{ validationMessage }}
    </div>
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <!-- Process and Material Selection Row -->
          <div class="row mt-3">
            <!-- Process Selector -->
            <div class="col-md-5">
              <div class="d-flex align-items-center">
                <label for="process-select" class="form-label mb-0 me-2">{{ translations.processes.select_process }}</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  :title="translations.processes_calculation_tooltip"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
              <select 
                id="process-select" 
                v-model="selectedProcessId" 
                class="form-select bg-dark text-white border-secondary"
                :disabled="!availableProcesses.length"
              >
                <option value="" disabled>{{ translations.processes.select_process }}</option>
                <option 
                  v-for="process in availableProcesses" 
                  :key="process.id" 
                  :value="process.id"
                >
                  {{ process.description }}
                </option>
              </select>
            </div>

            <!-- Material Selector -->
            <div class="col-md-5">
              <div class="d-flex align-items-center">
                <label for="material-select" class="form-label mb-0 me-2">{{ translations.processes.select_material }}</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  :title="translations.processes_material_tooltip || 'Selecciona el material al que se aplicará el proceso'"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
              <select 
                id="material-select" 
                v-model="selectedMaterialId" 
                class="form-select bg-dark text-white border-secondary"
                :disabled="!productMaterials.length"
              >
                <option value="" disabled>{{ translations.processes.select_material }}</option>
                <option 
                  v-for="material in productMaterials" 
                  :key="material.id" 
                  :value="material.id"
                >
                  {{ material.description }}
                </option>
              </select>
            </div>

            <!-- Add Process Button -->
            <div class="col-md-2 d-flex align-items-end">
              <button 
                class="btn btn-primary w-100" 
                @click="addProcess" 
                :disabled="!canAdd"
                :title="validationMessage"
              >
                <i class="fa fa-plus me-1"></i> {{ translations.processes.add_process }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

      <div v-if="!productProcesses.length" class="text-center my-5">
        <p class="text-muted">{{ translations.processes.no_processes }}</p>
      </div>

      <!-- Table view for medium and large screens -->
      <div class="green-accent-panel mt-4" v-if="productProcesses.length">
        <div class="card">
          <div class="card-body p-0">
            <!-- Desktop Table -->
            <div class="d-none d-md-block">
              <table class="table table-dark table-striped mb-0">
                <thead>
                  <tr>
                    <th style="width: 45%">{{ translations.processes.description }}</th>
                    <th style="width: 10%">{{ translations.processes.unit }}</th>
                    <th style="width: 15%">{{ translations.processes.applied_to }}</th>
                    <th style="width: 10%" class="text-end">{{ translations.processes.unit_price }}</th>
                    <th style="width: 12%" class="text-end">{{ translations.processes.total_price }}</th>
                    <th style="width: 8%" class="text-center">{{ translations.processes.actions }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(process, index) in productProcesses" :key="index">
                    <td class="text-truncate" style="max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="process.description">{{ process.description }}</td>
                    <td>{{ process.unit }}</td>
                    <td class="text-truncate" style="max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="process.materialDescription || 'No especificado'">{{ process.materialDescription || 'No especificado' }}</td>
                    <td class="text-end">
                      <input 
                        type="number" 
                        class="form-control form-control-sm text-end" 
                        v-model.number="process.unitPrice" 
                        min="0"
                        step="0.01"
                        @change="updateProcessUnitPrice(index)"
                        :title="translations.processes.unit_price"
                        data-toggle="tooltip"
                      />
                    </td>
                    <td class="text-end">{{ formatCurrency(process.price) }}</td>
                    <td class="text-center">
                      <div class="btn-group">
                        <button 
                          class="btn btn-sm btn-outline-danger" 
                          @click="removeProcess(index)"
                          :title="translations.processes.remove"
                        >
                          <i class="fa fa-trash"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
                <tfoot>
                  <tr>
                    <th colspan="4" class="text-end">{{ translations.processes.total }}:</th>
                    <th class="text-end">{{ formatCurrency(totalCost) }}</th>
                    <th></th>
                  </tr>
                </tfoot>
              </table>
            </div>

            <!-- Mobile Cards -->
            <div class="d-md-none">
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
                        :title="translations.processes.unit_price"
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
          </div>
        </div>
      </div>

      <!-- Global comments for all processes -->
      <div class="green-accent-panel mt-3 mb-4">
        <div class="card">
          <div class="card-body">
            <div class="form-group">
              <label for="process-comments" class="form-label">{{ translations.processes.comments_label }}</label>
              <textarea 
                id="process-comments" 
                class="form-control" 
                v-model="globalComments" 
                rows="3"
                :placeholder="translations.processes.comments_placeholder"
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
    productMaterials: {
      type: Array,
      default: () => []
    },
    translations: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      selectedProcessId: '',
      selectedMaterialId: '',
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
      // Validation: both process and material must be selected
      if (!this.selectedProcessId) {
        this.validationMessage = this.translations.processes.must_select_process || 'Debes seleccionar un proceso.';
        return;
      }
      if (!this.selectedMaterialId) {
        this.validationMessage = this.translations.processes.must_select_material || 'Debes seleccionar un material.';
        return;
      }
      if (!this.canAdd || !this.selectedProcess) return;
      this.validationMessage = '';
      
      const process = this.selectedProcess;
      const basePrice = parseFloat(process.price) || 0;
      let calculatedPrice = basePrice;

      // Find the selected material in the processes tab
      const selectedMaterial = this.productMaterials.find(m => m.id === this.selectedMaterialId);
      const materialSheets = selectedMaterial ? selectedMaterial.totalSheets : 0;
      const materialSquareMeters = selectedMaterial ? selectedMaterial.totalSquareMeters : 0;
      const materialDescription = selectedMaterial ? selectedMaterial.description : null;
      
      // Calculate price based on unit type and selected material
      if (process.unit === 'pieza') {
        calculatedPrice = basePrice * this.productQuantity;
      } else if (process.unit === 'pliego') {
        calculatedPrice = basePrice * materialSheets;
      } else if (process.unit === 'mt2') {
        calculatedPrice = basePrice * materialSquareMeters;
      }
      
      const newProcess = {
        id: process.id,
        description: process.description,
        unit: process.unit || 'unidad',
        unitPrice: basePrice, // Store the original unit price
        price: calculatedPrice, // Store the calculated total price
        materialId: selectedMaterial ? selectedMaterial.id : null,
        materialDescription: materialDescription
      };
      
      const updatedProcesses = [...this.productProcesses, newProcess];
      this.$emit('update:product-processes', updatedProcesses);
      
      // Calculate the new total cost including the new process
      const newTotalCost = this.totalCost + calculatedPrice;
      
      // Emit the updated total cost of processes
      this.$emit('update:processes-cost', newTotalCost);
      
      // Reset form
      this.selectedProcessId = '';
      this.selectedMaterialId = '';
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

      // Find the associated material for this process, if any
      let material = null;
      if (process.materialId) {
        material = this.productMaterials.find(m => m.id === process.materialId);
      }

      // Use the correct value for calculation
      if (process.unit === 'pieza') {
        calculatedPrice = basePrice * this.productQuantity;
      } else if (process.unit === 'pliego') {
        const sheets = material ? material.totalSheets : this.totalSheets;
        calculatedPrice = basePrice * sheets;
      } else if (process.unit === 'mt2') {
        const sqm = material ? material.totalSquareMeters : this.totalSquareMeters;
        calculatedPrice = basePrice * sqm;
      } else {
        calculatedPrice = basePrice;
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
        if (!process._needsRecalculation) {
          return process;
        }
        
        const basePrice = parseFloat(process.unitPrice) || 0;
        let calculatedPrice = basePrice;
        
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
        
        // Update the process with new calculations
        return {
          ...process,
          price: calculatedPrice,
          _needsRecalculation: false
        };
      });
      
      // Emit updated processes
      this.$emit('update:product-processes', updatedProcesses);
      
      // Calculate and emit new total cost
      const newTotalCost = updatedProcesses.reduce((sum, process) => sum + (parseFloat(process.price) || 0), 0);
      this.$emit('update:processes-cost', newTotalCost);
    },
    initializeTooltips() {
      // Dispose existing tooltips first
      this.disposeTooltips();
      
      // Initialize new tooltips
      const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
      tooltipTriggerList.forEach(tooltipTriggerEl => {
        new bootstrap.Tooltip(tooltipTriggerEl, {
          html: true,
          placement: tooltipTriggerEl.dataset.bsPlacement || 'bottom'
        });
      });
    },
    disposeTooltips() {
      const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
      tooltips.forEach(element => {
        const tooltip = bootstrap.Tooltip.getInstance(element);
        if (tooltip) {
          tooltip.dispose();
        }
      });
    },
    handleLanguageChange() {
      // Reinitialize tooltips when language changes
      this.$nextTick(() => {
        this.initializeTooltips();
      });
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
    this.initializeTooltips();

    // Listen for language changes
    window.addEventListener('languageChanged', this.handleLanguageChange);

    // Emit initial processes cost when component mounts
    const initialCost = this.productProcesses.reduce((sum, process) => {
      return sum + (parseFloat(process.price) || 0);
    }, 0);
    
    this.$emit('update:processes-cost', initialCost);
  },
  beforeUnmount() {
    // Clean up event listener
    window.removeEventListener('languageChanged', this.handleLanguageChange);
    
    // Clean up tooltips
    this.disposeTooltips();
  }
}
</script>

<style scoped>
.processes-validation-message {
  color: #ff6b6b;
  background: #23272b;
  border: 1px solid #ff6b6b;
  border-radius: 4px;
  padding: 0.5rem 1rem;
  font-size: 1rem;
  margin-bottom: 0.5rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}
</style>