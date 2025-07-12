<template>
  <div class="processes-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <!-- Process Type Toggle -->
            <div class="col-md-12 mb-2">
              <div class="d-flex align-items-center mb-2">
                <label class="form-label mb-0 me-3">{{ translations.processes.process_type || 'Tipo de Proceso' }}</label>
                <div class="btn-group" role="group">
                  <input type="radio" class="btn-check" name="processType" id="materialProcess" value="material" v-model="processType" />
                  <label class="btn btn-outline-primary btn-sm" for="materialProcess">
                    <i class="fa fa-box me-1"></i>{{ translations.processes.material_process || 'Proceso de Material' }}
                  </label>
                  <input type="radio" class="btn-check" name="processType" id="productProcess" value="product" v-model="processType" />
                  <label class="btn btn-outline-primary btn-sm" for="productProcess">
                    <i class="fa fa-cube me-1"></i>{{ translations.processes.product_process || 'Proceso de Producto' }}
                  </label>
                </div>
              </div>
            </div>

            <!-- Material Selector -->
            <div class="col-md-4 mb-2">
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
                :track-by="'materialInstanceId'"
                :label="'displayName'"
                :placeholder="''"
                :disabled="!productMaterials.length || processType === 'product'"
                :select-label="''"
              />
              <small v-if="processType === 'product'" class="text-muted">
                <i class="fa fa-info-circle me-1"></i>{{ translations.processes.product_process_info || 'Este proceso se aplicará al producto completo' }}
              </small>
            </div>

            <!-- Process Selector -->
            <div class="col-md-4 mb-2">
              <div class="d-flex align-items-center mb-2">
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
                :options="filteredProcesses"
                :track-by="'id'"
                :label="'description'"
                :placeholder="''"
                :disabled="!filteredProcesses.length"
                :select-label="''"
                @select="onProcessSelect"
              />
              <small v-if="processType === 'product' && !filteredProcesses.length" class="text-muted">
                <i class="fa fa-info-circle me-1"></i>{{ translations.processes.no_product_processes || 'No hay procesos de piezas disponibles para aplicar al producto' }}
              </small>
            </div>

            <!-- Veces Input THIRD (narrower) -->
            <div class="col-md-2 mb-2">
              <label class="form-label mb-0">{{ translations.processes.times || 'Veces' }}</label>
              <input
                type="number"
                class="form-control text-end"
                v-model.number="veces"
                min="1"
                step="1"
                style="width: 80px; max-width: 100%;"
              />
            </div>

            <!-- Add Process Button FOURTH (same row) -->
            <div class="col-md-2 mb-2 d-flex align-items-end">
              <button 
                class="btn btn-primary w-100" 
                @click="addProcess" 
                :disabled="!canAdd"
                style="min-width: 100px;"
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
                <div class="d-flex justify-content-between align-items-center">
                  <div>
                    <strong>
                      <span v-if="materialId === 'product'">
                        {{ getMaterialDescription(materialId) }}
                      </span>
                      <span v-else>
                        {{ translations.processes.material || 'Material' }}: {{ getMaterialDescription(materialId) }}
                      </span>
                    </strong>
                  </div>
                  <div class="d-flex align-items-center gap-3" v-if="materialId !== 'product'">
                    <span class="text-light material-header-text">
                      <i class="fa me-1"></i>{{ getMaterialPieces(materialId) }} {{ translations.processes.sheets || 'pliegos' }}
                    </span>
                    <span class="text-light material-header-text">
                      <i class="fa me-1"></i>{{ getMaterialSquareMeters(materialId) }} m²
                    </span>
                  </div>
                  <div class="d-flex align-items-center gap-3" v-else>
                    <span class="text-light material-header-text">
                      {{ productQuantity }} {{ translations.processes.pieces || 'pzas' }}
                    </span>
                  </div>
                </div>
              </div>
              <!-- Table for this material -->
              <div class="table-responsive d-none d-md-block">
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
              <!-- Mobile card layout -->
              <div class="d-block d-md-none">
                <!-- Mobile Material Header -->
                <div class="bg-dark text-white px-3 py-2">
                  <div class="d-flex flex-column">
                    <div class="fw-bold mb-1">
                      <span v-if="materialId === 'product'">
                        {{ getMaterialDescription(materialId) }}
                      </span>
                      <span v-else>
                        {{ translations.processes.material || 'Material' }}: {{ getMaterialDescription(materialId) }}
                      </span>
                    </div>
                    <div class="d-flex justify-content-between align-items-center" v-if="materialId !== 'product'">
                      <span class="text-light material-header-text">
                        <i class="fa fa-hashtag me-1"></i>{{ getMaterialPieces(materialId) }} {{ translations.processes.sheets || 'pliegos' }}
                      </span>
                      <span class="text-light material-header-text">
                        <i class="fa fa-ruler-combined me-1"></i>{{ getMaterialSquareMeters(materialId) }} m²
                      </span>
                    </div>
                    <div class="d-flex justify-content-between align-items-center" v-else>
                      <span class="text-light material-header-text">
                        {{ productQuantity }} {{ translations.processes.pieces || 'pzas' }}
                      </span>
                    </div>
                  </div>
                </div>
                <div v-for="(process, index) in processes" :key="index" class="card mb-3 shadow-sm">
                  <div class="card-body p-2">
                    <!-- Process name and unit -->
                    <h6 class="card-title mb-2">
                      <i class="fa fa-cogs me-1"></i>{{ process.description }}
                      <span class="text-secondary">({{ process.unit }})</span>
                    </h6>
                    <!-- Editable fields grid -->
                    <div class="row g-2 mb-2 text-center">
                      <div class="col-4 d-flex flex-column align-items-center">
                        <span>
                          <i class="fa fa-redo me-1"></i>
                          <input 
                            type="number" 
                            class="form-control form-control-sm text-center p-2 w-100 editable-badge d-inline-block"
                            v-model.number="process.veces" 
                            min="1"
                            step="1"
                            @change="updateProcessField(materialId, index, 'veces', process.veces)"
                            style="max-width: 70px; display: inline-block;"
                          /> <span class="text-muted">x</span>
                        </span>
                      </div>
                      <div class="col-4 d-flex flex-column align-items-center">
                        <span>
                          <i class="fa fa-dollar-sign me-1"></i>
                          <input 
                            type="number" 
                            class="form-control form-control-sm text-center p-2 w-100 editable-badge d-inline-block"
                            v-model.number="process.unitPrice" 
                            min="0"
                            step="0.01"
                            @change="updateProcessField(materialId, index, 'unitPrice', process.unitPrice)"
                            style="max-width: 70px; display: inline-block;"
                          /> <span class="text-muted">$</span>
                        </span>
                      </div>
                      <div class="col-4 d-flex flex-column align-items-center">
                        <span>
                          <i class="fa fa-calculator me-1"></i>
                          {{ formatCurrency(process.price) }} <span class="text-muted">$</span>
                        </span>
                      </div>
                    </div>
                    <!-- Delete button row -->
                    <div class="row g-2 mb-2 text-center">
                      <div class="col-12 d-flex justify-content-end align-items-center">
                        <button 
                          class="btn btn-sm btn-outline-danger" 
                          @click="removeProcess(materialId, index)"
                          :title="translations.processes.remove"
                        >
                          <i class="fa fa-trash"></i>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="card bg-dark text-white">
                  <div class="card-body py-2">
                    <div class="d-flex justify-content-between align-items-center">
                      <span class="fw-bold">{{ translations.processes.total }}:</span>
                      <span class="fs-5">{{ formatCurrency(processes.reduce((sum, p) => sum + (parseFloat(p.price) || 0), 0)) }}</span>
                    </div>
                  </div>
                </div>
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
    productDescription: {
      type: String,
      default: ''
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
      processType: 'material', // 'material' or 'product'
    }
  },
  computed: {
    canAdd() {
      if (!this.selectedProcessId) return false;
      const process = this.selectedProcess;
      if (!process) return false;
      
      // For product-level processes, we don't need material selection
      if (this.processType === 'product') {
        if (process.unit === 'pieza') {
          if (!this.productQuantity || this.productQuantity <= 0) return false;
          if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) return false;
        }
        return true;
      }
      
      // For material-level processes, we need material selection
      if (!this.selectedMaterialId) return false;
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
    },
    filteredProcesses() {
      if (this.processType === 'product') {
        // For product-level processes, only show processes with 'pieza' unit
        return this.availableProcesses.filter(process => {
          const unitStr = typeof process.unit === 'string' 
            ? process.unit 
            : (process.unit?.name || process.unit?.abbreviation || '');
          return unitStr.toLowerCase().includes('pieza');
        });
      } else {
        // For material-level processes, show all processes
        return this.availableProcesses;
      }
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
      if (!this.selectedProcessId) {
        window.showWarning('Selecciona un proceso');
        return;
      }
      
      const process = this.selectedProcessId;
      const basePrice = parseFloat(process.price) || 0;
      let calculatedPrice = basePrice;
      
      if (this.processType === 'product') {
        // Product-level process
        if (process.unit === 'pieza') {
          calculatedPrice = basePrice * this.productQuantity * this.veces;
        } else {
          // For other units, use the base price * veces
          calculatedPrice = basePrice * this.veces;
        }
        
        const newProcess = {
          id: process.id,
          description: process.description,
          unit: process.unit || 'unidad',
          unitPrice: basePrice,
          veces: this.veces,
          price: calculatedPrice,
          materialId: 'product',
          materialDescription: 'Producto'
        };
        
        const updated = { ...this.productProcessesByMaterial };
        if (!updated['product']) updated['product'] = [];
        updated['product'] = [...updated['product'], newProcess];
        this.$emit('update:product-processes-by-material', updated);
        this.$emit('update:processes-cost', this.totalCost + calculatedPrice);
      } else {
        // Material-level process
        if (!this.selectedMaterialId) {
          window.showWarning('Selecciona material y proceso');
          return;
        }
        
        const selectedMaterial = this.selectedMaterialId;
        const materialId = selectedMaterial.materialInstanceId || selectedMaterial.id;
        const materialDescription = selectedMaterial.displayName || selectedMaterial.description;
        const materialSheets = selectedMaterial.totalSheets;
        const materialSquareMeters = selectedMaterial.totalSquareMeters;
        
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
      }
      
      this.selectedProcessId = null;
      this.selectedMaterialId = null;
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
      // First try to find by materialInstanceId (for numbered materials)
      let material = this.productMaterials.find(m => m.materialInstanceId === materialId);
      
      // If not found, try by id (for backward compatibility)
      if (!material) {
        material = this.productMaterials.find(m => m.id == materialId);
      }
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
      // Handle product-level processes
      if (materialId === 'product') {
        return this.productDescription ? `Producto: ${this.productDescription}` : 'Producto';
      }
      
      // First try to find by materialInstanceId (for numbered materials)
      let mat = this.productMaterials.find(m => m.materialInstanceId === materialId);
      
      // If not found, try by id (for backward compatibility)
      if (!mat) {
        mat = this.productMaterials.find(m => m.id === Number(materialId));
      }
      
      return mat ? (mat.displayName || mat.description) : 'Material';
    },
    getMaterialPieces(materialId) {
      // Handle product-level processes
      if (materialId === 'product') {
        return this.productQuantity || 0;
      }
      
      // First try to find by materialInstanceId (for numbered materials)
      let mat = this.productMaterials.find(m => m.materialInstanceId === materialId);
      
      // If not found, try by id (for backward compatibility)
      if (!mat) {
        mat = this.productMaterials.find(m => m.id === Number(materialId));
      }
      
      if (!mat) return 0;
      
      // Try different property names that might contain the pieces count
      return mat.totalSheets || mat.piecesPerMaterial || mat.total_sheets || 0;
    },
    getMaterialSquareMeters(materialId) {
      // Handle product-level processes
      if (materialId === 'product') {
        // Calculate total square meters from all materials
        const totalSquareMeters = this.productMaterials.reduce((sum, material) => {
          return sum + (material.totalSquareMeters || 0);
        }, 0);
        return totalSquareMeters.toFixed(2);
      }
      
      // First try to find by materialInstanceId (for numbered materials)
      let mat = this.productMaterials.find(m => m.materialInstanceId === materialId);
      
      // If not found, try by id (for backward compatibility)
      if (!mat) {
        mat = this.productMaterials.find(m => m.id === Number(materialId));
      }
      
      if (!mat) return '0.00';
      
      // Try different property names that might contain the square meters
      const squareMeters = mat.totalSquareMeters || mat.total_square_meters || 0;
      return squareMeters.toFixed(2);
    },
    updateProcessCalculations() {
      // Recalculate all process prices when material properties change
      const updated = { ...this.productProcessesByMaterial };
      
      Object.keys(updated).forEach(materialId => {
        // First try to find by materialInstanceId (for numbered materials)
        let material = this.productMaterials.find(m => m.materialInstanceId === materialId);
        
        // If not found, try by id (for backward compatibility)
        if (!material) {
          material = this.productMaterials.find(m => m.id === Number(materialId));
        }
        
        if (!material) return;
        
        updated[materialId] = updated[materialId].map(process => {
          const basePrice = parseFloat(process.unitPrice) || 0;
          const veces = parseInt(process.veces) || 1;
          let calculatedPrice = basePrice;
          
          if (process.unit === 'pieza') {
            calculatedPrice = basePrice * this.productQuantity * veces;
          } else if (process.unit === 'pliego') {
            calculatedPrice = basePrice * (material.totalSheets || 0) * veces;
          } else if (process.unit === 'mt2') {
            calculatedPrice = basePrice * (material.totalSquareMeters || 0) * veces;
          }
          
          return { ...process, price: calculatedPrice };
        });
      });
      
      this.$emit('update:product-processes-by-material', updated);
      const newTotalCost = Object.values(updated).flat().reduce((sum, p) => sum + (parseFloat(p.price) || 0), 0);
      this.$emit('update:processes-cost', newTotalCost);
    },
    ensureMaterialInstanceIds() {
      // Ensure all materials have the required properties for backward compatibility
      this.productMaterials.forEach((material, index) => {
        if (!material.materialInstanceId) {
          // For existing materials without instance IDs, create them
          const existingMaterialsOfSameType = this.productMaterials.filter(m => m.id === material.id);
          const materialInstanceNumber = existingMaterialsOfSameType.indexOf(material) + 1;
          const materialInstanceId = `${material.id}_${materialInstanceNumber}`;
          
          // Update the material with the new properties
          const updatedMaterial = {
            ...material,
            materialInstanceId,
            materialInstanceNumber,
            displayName: material.displayName || `${material.description} (${materialInstanceNumber})`
          };
          
          this.productMaterials[index] = updatedMaterial;
        }
      });
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
    productMaterials: {
      handler(newMaterials) {
        // Ensure material instance IDs are set for all materials
        this.ensureMaterialInstanceIds();
        // Update process calculations when material properties change
        this.updateProcessCalculations();
      },
      deep: true
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
    },
    processType(newType) {
      // Reset material selection when switching to product-level processes
      if (newType === 'product') {
        this.selectedMaterialId = null;
      }
      
      // Reset process selection if the current process is not available in the new filtered list
      if (this.selectedProcessId) {
        const isProcessAvailable = this.filteredProcesses.some(p => p.id === this.selectedProcessId.id);
        if (!isProcessAvailable) {
          this.selectedProcessId = null;
        }
      }
    }
  },
  mounted() {
    // Initialize tooltips
    this.initializeTooltips();

    // Listen for language changes
    window.addEventListener('languageChanged', this.handleLanguageChange);

    // Ensure material instance IDs are set for all materials
    this.ensureMaterialInstanceIds();

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

/* Custom toggle styling for process type */
.btn-outline-primary {
  color: #42b983 !important;
  border-color: #42b983 !important;
  background: #23272b !important;
  transition: background 0.2s, color 0.2s, border 0.2s;
}
.btn-outline-primary:hover, .btn-outline-primary:focus {
  background: #2d3a36 !important;
  color: #fff !important;
  border-color: #42b983 !important;
}
.btn-check:checked + .btn-outline-primary,
.btn-outline-primary.active, .btn-outline-primary:active, .show > .btn-outline-primary.dropdown-toggle {
  color: #fff !important;
  background-color: #42b983 !important;
  border-color: #42b983 !important;
  box-shadow: none !important;
}
.btn-check:focus + .btn-outline-primary, .btn-outline-primary:focus {
  box-shadow: 0 0 0 0.15rem rgba(66,185,131,0.25) !important;
}

/* Make sure toggle buttons have rounded corners and spacing */
.btn-group .btn-outline-primary {
  border-radius: 0.5rem !important;
  margin-right: 0.25rem;
}
.btn-group .btn-outline-primary:last-child {
  margin-right: 0;
}

/* Override for disabled vue-multiselect in dark theme to match enabled style exactly */
::v-deep .multiselect--disabled .multiselect__tags {
  border: 1px solid #495057 !important;
  border-radius: 4px !important;
  background: #2c3136 !important;
  color: #aaa !important;
  cursor: not-allowed;
}
::v-deep .multiselect--disabled .multiselect__select,
::v-deep .multiselect--disabled .multiselect__single {
  background: #2c3136 !important;
  color: #aaa !important;
  cursor: not-allowed;
}

/* Material header text styling */
.material-header-text {
  font-size: 0.9rem;
  opacity: 0.9;
}

/* Mobile material header styling */
@media (max-width: 767.98px) {
  .material-header-text {
    font-size: 0.8rem;
  }
}
</style>