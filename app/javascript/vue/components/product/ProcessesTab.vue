<template>
  <div class="processes-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <!-- Material Selector FIRST -->
            <div class="col-md-4">
              <div class="d-flex align-items-center mb-2">
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
              <multiselect
                v-model="selectedMaterialId"
                :options="productMaterials"
                :track-by="'id'"
                :label="'description'"
                :placeholder="''"
                :disabled="!productMaterials.length"
                :select-label="translations.extras_tab.press_enter_to_select"
              />
            </div>

            <!-- Process Selector SECOND -->
            <div class="col-md-4">
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
              <multiselect
                v-model="selectedProcessId"
                :options="availableProcesses"
                :track-by="'id'"
                :label="'description'"
                :placeholder="''"
                :disabled="!availableProcesses.length"
                :select-label="translations.extras_tab.press_enter_to_select"
                @select="onProcessSelect"
              />
            </div>

            <!-- Veces Input THIRD -->
            <div class="col-md-2">
              <label class="form-label mb-0">{{ translations.processes.times || 'Veces' }}</label>
              <input
                type="number"
                class="form-control"
                v-model.number="veces"
                min="1"
                step="1"
                style="width: 100%;"
              />
            </div>

            <!-- Add Process Button FOURTH -->
            <div class="col-md-2 d-flex align-items-end">
              <button 
                class="btn btn-primary w-100" 
                @click="addProcess" 
                :disabled="!canAdd"
              >
                <i class="fa fa-plus me-1"></i> {{ translations.processes.add_process }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

      <div v-if="!Object.keys(productProcessesByMaterial).length" class="text-center my-1">
        <p class="text-muted">{{ translations.processes.no_processes }}</p>
      </div>

      <!-- Each material gets its own green-accent-panel -->
      <div v-if="Object.keys(productProcessesByMaterial).length">
        <div
          v-for="(processes, materialId) in productProcessesByMaterial"
          :key="materialId"
          class="green-accent-panel mt-1 material-process-list"
        >
          <div class="card">
            <div class="card-body p-0">
              <!-- Material Header -->
              <div class="bg-dark text-white px-3 py-2 rounded-top">
                <strong>{{ translations.processes.material || 'Material' }}: {{ getMaterialDescription(materialId) }}</strong>
              </div>
              <!-- Table for this material -->
              <div class="table-responsive">
                <table class="table table-striped table-hover mb-0">
                  <thead>
                    <tr>
                      <th style="width: 35%">{{ translations.processes.process }}</th>
                      <th style="width: 10%">{{ translations.processes.unit }}</th>
                      <th style="width: 10%">{{ translations.processes.times || 'Veces' }}</th>
                      <th style="width: 15%" class="text-end">{{ translations.processes.unit_price }}</th>
                      <th style="width: 15%" class="text-end">{{ translations.processes.total_price }}</th>
                      <th style="width: 10%" class="text-center">{{ translations.processes.actions }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(process, index) in processes" :key="index">
                      <td class="text-truncate" style="max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="process.description">{{ process.description }}</td>
                      <td>{{ process.unit }}</td>
                      <td>
                        <input 
                          type="number" 
                          class="form-control form-control-sm text-end" 
                          v-model.number="process.veces" 
                          min="1"
                          step="1"
                          @change="updateProcessField(materialId, index, 'veces', process.veces)"
                          :title="translations.processes.times || 'Veces'"
                        />
                      </td>
                      <td class="text-end">
                        <input 
                          type="number" 
                          class="form-control form-control-sm text-end" 
                          v-model.number="process.unitPrice" 
                          min="0"
                          step="0.01"
                          @change="updateProcessField(materialId, index, 'unitPrice', process.unitPrice)"
                          :title="translations.processes.unit_price"
                          data-toggle="tooltip"
                        />
                      </td>
                      <td class="text-end">{{ formatCurrency(process.price) }}</td>
                      <td class="text-center">
                        <div class="btn-group">
                          <button 
                            class="btn btn-sm btn-outline-danger" 
                            @click="removeProcess(materialId, index)"
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
                      <th class="text-end">
                        {{ formatCurrency(processes.reduce((sum, p) => sum + (parseFloat(p.price) || 0), 0)) }}
                      </th>
                      <th></th>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>
          </div>
        </div>
        <!-- Total general de procesos row -->
        <div class="d-flex justify-content-end align-items-center bg-dark text-white px-3 py-2" style="border-top: 2px solid var(--cotalo-green); font-size: 1.1rem;">
          <span class="me-3 fw-bold">{{ translations.processes.total_general }}</span>
          <span class="fw-bold" style="min-width: 160px; text-align: right;">{{ formatCurrency(totalCost) }}</span>
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
                :placeholder="''"
                @change="updateGlobalComments"
              ></textarea>
            </div>
          </div>
        </div>
      </div>
    </div>
  
</template>

<script>
import Multiselect from 'vue-multiselect'
import 'vue-multiselect/dist/vue-multiselect.min.css'

export default {
  name: 'ProcessesTab',
  components: {
    Multiselect,
  },
  props: {
    productProcessesByMaterial: {
      type: Object,
      default: () => ({})
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
      selectedProcessId: null,
      selectedMaterialId: null,
      veces: 1,
      globalComments: this.comments || '',
    }
  },
  computed: {
    canAdd() {
      if (!this.selectedProcessId || !this.selectedMaterialId) return false;
      const process = this.selectedProcess;
      if (!process) return false;
      if (!this.productMaterials || this.productMaterials.length === 0) return false;
      if (process.unit === 'mt2' || process.unit === 'pliego') return true;
      if (process.unit === 'pieza') {
        if (!this.productQuantity || this.productQuantity <= 0) return false;
        if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) return false;
      }
      return true;
    },
    selectedProcess() {
      return this.selectedProcessId;
    },
    totalCost() {
      return Object.values(this.productProcessesByMaterial).flat().reduce((sum, process) => sum + (parseFloat(process.price) || 0), 0);
    }
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value || 0);
    },
    addProcess() {
      if (!this.selectedProcessId || !this.selectedMaterialId) {
        window.showWarning('Selecciona material y proceso');
        return;
      }
      const process = this.selectedProcessId;
      const selectedMaterial = this.selectedMaterialId;
      const materialId = selectedMaterial.id;
      const materialDescription = selectedMaterial.description;
      const materialSheets = selectedMaterial.totalSheets;
      const materialSquareMeters = selectedMaterial.totalSquareMeters;
      const basePrice = parseFloat(process.price) || 0;
      let calculatedPrice = basePrice;
      if (process.unit === 'pieza') {
        calculatedPrice = basePrice * this.productQuantity * this.veces;
      } else if (process.unit === 'pliego') {
        calculatedPrice = basePrice * materialSheets * this.veces;
      } else if (process.unit === 'mt2') {
        calculatedPrice = basePrice * materialSquareMeters * this.veces;
      }
      const newProcess = {
        id: process.id,
        description: process.description,
        unit: process.unit || 'unidad',
        unitPrice: basePrice,
        veces: this.veces,
        price: calculatedPrice,
        materialId,
        materialDescription
      };
      const updated = { ...this.productProcessesByMaterial };
      if (!updated[materialId]) updated[materialId] = [];
      updated[materialId] = [...updated[materialId], newProcess];
      this.$emit('update:product-processes-by-material', updated);
      this.$emit('update:processes-cost', this.totalCost + calculatedPrice);
      this.selectedProcessId = null;
      this.veces = 1;
    },
    removeProcess(materialId, index) {
      const updated = { ...this.productProcessesByMaterial };
      const removed = updated[materialId][index];
      updated[materialId] = updated[materialId].filter((_, i) => i !== index);
      if (updated[materialId].length === 0) delete updated[materialId];
      this.$emit('update:product-processes-by-material', updated);
      this.$emit('update:processes-cost', this.totalCost - (parseFloat(removed.price) || 0));
      window.showSuccess(`Proceso "${removed.description}" eliminado exitosamente`);
    },
    updateProcessField(materialId, index, field, value) {
      const updated = { ...this.productProcessesByMaterial };
      const process = { ...updated[materialId][index], [field]: value };
      const basePrice = parseFloat(process.unitPrice) || 0;
      const veces = parseInt(process.veces) || 1;
      let calculatedPrice = basePrice;
      const material = this.productMaterials.find(m => m.id == materialId);
      if (process.unit === 'pieza') {
        calculatedPrice = basePrice * this.productQuantity * veces;
      } else if (process.unit === 'pliego') {
        calculatedPrice = basePrice * (material ? material.totalSheets : 0) * veces;
      } else if (process.unit === 'mt2') {
        calculatedPrice = basePrice * (material ? material.totalSquareMeters : 0) * veces;
      }
      process.price = calculatedPrice;
      updated[materialId] = updated[materialId].map((p, i) => i === index ? process : p);
      this.$emit('update:product-processes-by-material', updated);
      const newTotalCost = Object.values(updated).flat().reduce((sum, p) => sum + (parseFloat(p.price) || 0), 0);
      this.$emit('update:processes-cost', newTotalCost);
      window.showInfo(`Campo actualizado para proceso "${process.description}"`);
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
      window.showInfo('Comentarios de procesos actualizados');
    },
    onProcessSelect(selectedOption) {
      if (!selectedOption) {
        return;
      }

      // Check if there are any materials available
      if (!this.productMaterials || this.productMaterials.length === 0) {
        window.showWarning('No hay materiales disponibles. Agrega materiales en la pestaña de materiales primero.');
        this.selectedProcessId = null; // Reset selector
        return;
      }

      // Validate product dimensions and quantity for processes that require them
      if (selectedOption.unit === 'pieza') {
        if (!this.productQuantity || this.productQuantity <= 0) {
          window.showWarning('Por favor, especifica la cantidad de piezas del producto en la pestaña de información general');
          this.selectedProcessId = null; // Reset selector
          return;
        }
        if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
          window.showWarning('Por favor, especifica el ancho y largo del producto en la pestaña de información general');
          this.selectedProcessId = null; // Reset selector
          return;
        }
      }
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
    },
    getMaterialDescription(materialId) {
      const mat = this.productMaterials.find(m => m.id === Number(materialId));
      return mat ? mat.description : 'Material';
    }
  },
  watch: {
    productQuantity() {
      this.updateProcessCalculations();
    },
    totalSheets() {
      this.updateProcessCalculations();
    },
    totalSquareMeters() {
      this.updateProcessCalculations();
    },
    productProcessesByMaterial: {
      handler(newProcesses) {
        const allProcesses = Object.values(newProcesses).flat();
        const needsRecalculation = allProcesses.some(process => process._needsRecalculation);
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
    const initialCost = Object.values(this.productProcessesByMaterial).flat().reduce((sum, process) => {
      return sum + (parseFloat(process.price) || 0);
    }, 0);
    
    this.$emit('update:processes-cost', initialCost);
    
    // Show info notification if there are existing processes
    if (Object.keys(this.productProcessesByMaterial).length > 0) {
      window.showInfo(`${Object.values(this.productProcessesByMaterial).flat().length} proceso(s) cargado(s) - Total: ${this.formatCurrency(initialCost)}`);
    }
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
.material-process-list {
  margin-bottom: 0.75rem;
}
.material-process-list:last-child {
  margin-bottom: 0;
}
</style>