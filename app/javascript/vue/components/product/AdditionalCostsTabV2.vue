<template>
  <div class="additional-costs-tab-v2">

    <!-- Global Processes Section -->
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-header">
          <div class="d-flex justify-content-between align-items-center">
            <h5 class="mb-0">
              <i class="fa fa-cogs me-2"></i>Procesos globales del producto
            </h5>
            <button 
              class="btn btn-outline-success btn-sm"
              data-bs-toggle="tooltip"
              data-bs-placement="left"
              data-bs-html="true"
              :title="translations.processes_calculation_tooltip || '¿Cómo se calculan los costos de procesos?<br>• Precio unitario: Costo por unidad de medida del proceso (por millar, por pieza, etc.)<br>• Aplicado a: El producto completo o una parte específica<br>• Precio total: Resultado de aplicar el precio unitario al volumen definido del producto'"
            >
              <i class="fa fa-question-circle"></i>
            </button>
          </div>
        </div>
        <div class="card-body">
          <!-- Add Global Process Section -->
          <div class="d-flex align-items-center gap-3 mb-4">
            <div class="d-flex align-items-center">
              <label for="global-process-select" class="form-label mb-0 me-2">Seleccionar proceso</label>
            </div>
            <div class="flex-grow-1">
              <multiselect
                v-model="selectedGlobalProcessId"
                :options="filteredAvailableProcesses"
                :track-by="'id'"
                :label="'description'"
                :placeholder="''"
                :disabled="!filteredAvailableProcesses.length"
                @select="onGlobalProcessSelect"
                :select-label="''"
                :remove-label="''"
                :deselect-label="''"
              />
            </div>
            <div class="d-flex align-items-center">
              <label for="global-process-veces" class="form-label mb-0 me-2">Veces</label>
              <input 
                id="global-process-veces" 
                type="text" 
                inputmode="decimal"
                v-model.number="globalProcessVeces" 
                class="form-control" 
                min="1" 
                step="1"
                :disabled="!selectedGlobalProcessId"
                style="width: 80px;"
              />
            </div>
            <!-- Show product quantity for reference when adding global processes -->
            <div class="d-flex align-items-center">
              <label class="form-label mb-0 me-2">Piezas</label>
              <span class="text-light">{{ Intl.NumberFormat('en-US', { maximumFractionDigits: 0 }).format((product.data.general_info && product.data.general_info.quantity) || 0) }}</span>
            </div>
            <div>
              <a
                href="/manufacturing_processes"
                target="_blank"
                rel="noopener"
                class="btn btn-outline-success"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Abrir lista de procesos en una pestaña nueva"
              >
                <i class="fa fa-cogs"></i>
              </a>
            </div>
            <div>
              <button 
                class="btn btn-primary" 
                @click="addGlobalProcess" 
                :disabled="!canAddGlobalProcess"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Agregar proceso global"
              >
                <i class="fa fa-plus me-1"></i> Agregar proceso
              </button>
            </div>
          </div>

          <!-- No Global Processes Message -->
          <div v-if="!product.data.global_processes.length" class="text-center my-5">
            <p class="text-muted">No hay procesos globales agregados. Los procesos globales se aplican a todo el producto.</p>
          </div>

          <!-- Global Processes List -->
          <div v-if="product.data.global_processes.length" class="global-processes-list">
            <!-- Headers Row -->
            <div class="process-item mb-3">
              <div class="process-container border rounded subtle-border">
                <div class="process-header d-flex align-items-center p-3">
                  <!-- Collapse/Expand global processes list -->
                  <button 
                    class="btn btn-sm btn-outline-secondary me-3"
                    @click="showGlobalProcessesList = !showGlobalProcessesList"
                    data-bs-toggle="tooltip"
                    data-bs-placement="top"
                    data-bs-trigger="hover"
                    tabindex="-1"
                    :title="showGlobalProcessesList ? 'Colapsar lista' : 'Mostrar lista'"
                  >
                    <i :class="showGlobalProcessesList ? 'fa fa-chevron-down' : 'fa fa-chevron-right'"></i>
                  </button>
                  <!-- Process Description Column -->
                  <div class="process-info process-description-column me-4" style="flex: 1 1 auto; min-width: 300px;">
                    <strong class="text-success">Descripción de proceso</strong>
                  </div>
                  
                  <!-- Process Details Columns -->
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 80px;">
                    <strong class="text-success">Unidad</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 60px;">
                    <strong class="text-success">Veces</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 100px;">
                    <strong class="text-success">Costo</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 80px;">
                    <strong class="text-success">Cara</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 120px;">
                    <strong class="text-success">Costo total</strong>
                  </div>
                  
                  <!-- Action Buttons -->
                  <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="flex: 0 0 80px;">
                    <strong class="text-success">Acciones</strong>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Process Items -->
            <div v-if="showGlobalProcessesList">
              <div v-for="(process, index) in product.data.global_processes" :key="process.id" class="process-item mb-3">
                <!-- Process Container -->
                <div class="process-container border rounded subtle-border">
                  <!-- Process Header -->
                  <div class="process-header d-flex align-items-center p-3">
                  <!-- Process Name -->
                  <div class="process-info process-description-column me-4" style="flex: 1 1 auto; min-width: 300px;">
                    <span class="process-name text-truncate d-block" :title="process.description">
                      {{ process.description }}
                    </span>
                  </div>
                  
                  <!-- Process Details Columns -->
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 80px;">
                    <div>{{ process.unit || '-' }}</div>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 60px;">
                    <input 
                      type="text" 
                      inputmode="decimal"
                      class="form-control form-control-sm text-end" 
                      v-model.number="process.veces" 
                      min="1"
                      step="1"
                      @blur="updateGlobalProcessCalculations(index)"
                      style="width: 50px;"
                    />
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 100px;">
                    <input 
                      type="text" 
                      inputmode="decimal"
                      class="form-control form-control-sm text-end" 
                      v-model.number="process.unitPrice" 
                      min="0"
                      step="0.01"
                      @blur="updateGlobalProcessCalculations(index)"
                      style="width: 80px;"
                    />
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 80px;">
                    <div>{{ getSideLabel(process.side) }}</div>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 120px;">
                    <div class="price-column">
                      {{ formatCurrency(process.price) }}
                    </div>
                  </div>
                  
                    <!-- Action Buttons -->
                    <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="flex: 0 0 80px;">
                      <button 
                        class="btn btn-sm btn-outline-danger" 
                        @click="removeGlobalProcess(index)"
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        tabindex="-1"
                        title="Eliminar proceso"
                      >
                        <i class="fa fa-trash"></i>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Indirect Costs Section -->
    <div class="green-accent-panel mt-4">
      <div class="card">
        <div class="card-header">
          <div class="d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center">
              <h5 class="mb-0 me-3">
                <i class="fa fa-plus-circle me-2"></i>Costos indirectos
              </h5>
              <!-- Include in Subtotal Checkbox -->
              <div class="form-check">
                <input 
                  class="form-check-input" 
                  type="checkbox" 
                  id="include-extras-subtotal" 
                  v-model="includeInSubtotal"
                  @change="updateIncludeInSubtotal"
                >
                <label class="form-check-label mb-0" for="include-extras-subtotal">
                  Incluir costos indirectos en el subtotal para el cálculo de merma y margen
                </label>
              </div>
            </div>
            <button 
              class="btn btn-outline-success btn-sm"
              data-bs-toggle="tooltip"
              data-bs-placement="left"
              data-bs-html="true"
              :title="(translations.extras_tab && translations.extras_tab.indirect_costs_tooltip) || '¿Qué son los costos indirectos?<br>Son costos adicionales que no dependen directamente de los materiales o procesos, pero que son necesarios para producir el producto.<br>Incluyen cosas como la fabricación de troqueles, placas offset, calibraciones o desarrollo de muestras físicas.'"
            >
              <i class="fa fa-question-circle"></i>
            </button>
          </div>
        </div>
        <div class="card-body">

          <!-- Add Indirect Cost Section -->
          <div class="d-flex align-items-center gap-3 mb-4">
            <div class="d-flex align-items-center">
              <label for="extra-select" class="form-label mb-0 me-2">Seleccionar costo indirecto</label>
            </div>
            <div class="flex-grow-1">
              <multiselect
                v-model="selectedExtraId"
                :options="availableExtras"
                :track-by="'id'"
                :label="'name'"
                :placeholder="''"
                :disabled="!availableExtras.length"
                @select="onExtraSelect"
                :select-label="''"
                :remove-label="''"
                :deselect-label="''"
              />
            </div>
            <div class="d-flex align-items-center">
              <label for="extra-quantity" class="form-label mb-0 me-2">Veces</label>
              <input 
                id="extra-quantity" 
                type="text" 
                inputmode="decimal"
                v-model.number="extraQuantity" 
                class="form-control" 
                min="1" 
                step="1"
                :disabled="!selectedExtraId"
                style="width: 80px;"
              />
            </div>
            <div>
              <a
                href="/indirect_costs"
                target="_blank"
                rel="noopener"
                class="btn btn-outline-success"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Abrir lista de costos indirectos en una pestaña nueva"
              >
                <i class="fa fa-plus-circle"></i>
              </a>
            </div>
            <div>
              <button 
                class="btn btn-primary" 
                @click="addExtra" 
                :disabled="!canAddExtra"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Agregar costo indirecto"
              >
                <i class="fa fa-plus me-1"></i> Agregar indirecto
              </button>
            </div>
          </div>

          <!-- No Extras Message -->
          <div v-if="!product.data.extras.length" class="text-center my-5">
            <p class="text-muted">No hay costos indirectos agregados. Los costos indirectos incluyen troqueles, placas, calibraciones, etc.</p>
          </div>

          <!-- Extras List -->
          <div v-if="product.data.extras.length" class="extras-list">
            <!-- Headers Row -->
            <div class="extra-item mb-3">
              <div class="extra-container border rounded subtle-border">
                <div class="extra-header d-flex align-items-center p-3">
                  <!-- Collapse/Expand extras list -->
                  <button 
                    class="btn btn-sm btn-outline-secondary me-3"
                    @click="showExtrasList = !showExtrasList"
                    data-bs-toggle="tooltip"
                    data-bs-placement="top"
                    data-bs-trigger="hover"
                    tabindex="-1"
                    :title="showExtrasList ? 'Colapsar lista' : 'Mostrar lista'"
                  >
                    <i :class="showExtrasList ? 'fa fa-chevron-down' : 'fa fa-chevron-right'"></i>
                  </button>
                  <!-- Extra Description Column -->
                  <div class="extra-info extra-description-column me-4" style="flex: 1 1 auto; min-width: 300px;">
                    <strong class="text-success">Descripción de costo indirecto</strong>
                  </div>
                  
                  <!-- Extra Details Columns -->
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 100px;">
                    <strong class="text-success">Unidad</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 80px;">
                    <strong class="text-success">Veces</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 120px;">
                    <strong class="text-success">Costo</strong>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 120px;">
                    <strong class="text-success">Costo total</strong>
                  </div>
                  
                  <!-- Action Buttons -->
                  <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="flex: 0 0 80px;">
                    <strong class="text-success">Acciones</strong>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Extra Items -->
            <div v-if="showExtrasList">
              <div v-for="(extra, index) in product.data.extras" :key="extra.id" class="extra-item mb-3">
                <!-- Extra Container -->
                <div class="extra-container border rounded subtle-border">
                  <!-- Extra Header -->
                  <div class="extra-header d-flex align-items-center p-3">
                  <!-- Extra Name -->
                  <div class="extra-info extra-description-column me-4" style="flex: 1 1 auto; min-width: 300px;">
                    <span class="extra-name text-truncate d-block" :title="extra.name || extra.description">
                      {{ extra.name || extra.description }}
                    </span>
                  </div>
                  
                  <!-- Extra Details Columns -->
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 100px;">
                    <div>{{ extra.unit || 'unidad' }}</div>
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 80px;">
                    <input 
                      type="text" 
                      inputmode="decimal"
                      class="form-control form-control-sm text-end" 
                      v-model.number="extra.quantity" 
                      min="1"
                      step="1"
                      @blur="updateExtraCalculations(index)"
                      style="width: 60px;"
                    />
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 120px;">
                    <input 
                      type="text" 
                      inputmode="decimal"
                      class="form-control form-control-sm text-end" 
                      v-model.number="extra.unit_price" 
                      min="0"
                      step="0.01"
                      @blur="updateExtraCalculations(index)"
                      style="width: 100px;"
                    />
                  </div>
                  <div class="d-flex align-items-center justify-content-end me-3" style="width: 120px;">
                    <div class="price-column">
                      {{ formatCurrency(extra.total_price || (extra.unit_price || extra.price) * extra.quantity) }}
                    </div>
                  </div>
                  
                    <!-- Action Buttons -->
                    <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="flex: 0 0 80px;">
                      <button 
                        class="btn btn-sm btn-outline-danger" 
                        @click="removeExtra(index)"
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        tabindex="-1"
                        title="Eliminar costo indirecto"
                      >
                        <i class="fa fa-trash"></i>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
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
  name: 'AdditionalCostsTabV2',
  components: {
    Multiselect,
  },
  props: {
    product: {
      type: Object,
      required: true
    },
    availableProcesses: {
      type: Array,
      required: true
    },
    availableExtras: {
      type: Array,
      required: true
    },
    translations: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      selectedGlobalProcessId: null,
      selectedExtraId: null,
      extraQuantity: 1,
      globalProcessVeces: 1,
      includeInSubtotal: true,
      showGlobalProcessesList: true,
      showExtrasList: true
    };
  },
  computed: {
    canAddGlobalProcess() {
      return !!this.selectedGlobalProcessId && this.globalProcessVeces > 0;
    },
    canAddExtra() {
      return !!this.selectedExtraId && this.extraQuantity > 0;
    },
    filteredAvailableProcesses() {
      // Filtrar procesos que SÍ tienen unidad "pieza"
      return this.availableProcesses.filter(process => 
        process.unit === 'pieza' || process.unit === 'piece'
      );
    },

  },
  created() {
    // Initialize includeInSubtotal from product data
    this.includeInSubtotal = this.product.data.include_extras_in_subtotal !== false;
  },
  mounted() {
    this.initializeTooltips();
  },
  methods: {
    initializeTooltips() {
      // Inicializar tooltips de Bootstrap
      this.$nextTick(() => {
        const rootEl = (this.$el && typeof this.$el.querySelectorAll === 'function') ? this.$el : document;
        const tooltipElements = rootEl.querySelectorAll('[data-bs-toggle="tooltip"]');
        tooltipElements.forEach(el => {
          if (window.bootstrap && window.bootstrap.Tooltip) {
            const existing = window.bootstrap.Tooltip.getInstance(el);
            const t = existing || new window.bootstrap.Tooltip(el);
            el.addEventListener('click', () => { try { t.hide(); } catch (e) {} });
            el.addEventListener('blur', () => { try { t.hide(); } catch (e) {} });
          }
        });
      });
    },
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value || 0);
    },
    
    onGlobalProcessSelect(selectedOption) {
      if (!selectedOption) return;
      
      // Reset veces to 1 when selecting a new process
      this.globalProcessVeces = 1;
      
      // Debug logging for quantity validation
      // Debug removed
      
      // Temporarily comment out validation to test
      // Validate product quantity
      // if (!this.product.data.general_info.quantity || this.product.data.general_info.quantity <= 0) {
      //   window.showWarning('Por favor, especifica la cantidad de piezas del producto');
      //   this.selectedGlobalProcessId = null;
      //   return;
      // }
    },
    
    addGlobalProcess() {
      if (!this.selectedGlobalProcessId) {
        return;
      }
      
      // selectedGlobalProcessId is now the full object, so we can use it directly
      const selectedProcess = this.selectedGlobalProcessId;
      
      if (!selectedProcess) {
        return;
      }
      
      // Debug logging for product structure
      // Debug removed
      
      // Debug logging for selected process
      // Debug removed
      
      // Calculate process price based on unit type
      const basePrice = parseFloat(selectedProcess.price) || 0;
      const veces = this.globalProcessVeces || 1; // Use the user-selected veces value
      const side = 'both'; // Global processes apply to both sides
      const sideMultiplier = side === 'both' ? 2 : 1;
      const productQuantity = this.product.data.general_info.quantity || 1;
      
      // Debug logging
      // Debug removed
      
      let calculatedPrice = basePrice;
      const unitStr = typeof selectedProcess.unit === 'string'
        ? selectedProcess.unit
        : (selectedProcess.unit && selectedProcess.unit.name || selectedProcess.unit && selectedProcess.unit.abbreviation || '');
      
      // Debug removed
      
      // Debug removed
      
      if (unitStr.toLowerCase().includes('pieza') || unitStr.toLowerCase().includes('pza')) {
        // Per piece
        calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
        // Debug removed
      } else if (unitStr.toLowerCase().includes('millar') || unitStr.toLowerCase().includes('mil')) {
        // Per thousand
        calculatedPrice = (basePrice * productQuantity * veces * sideMultiplier) / 1000;
        // Debug removed
      } else {
        // Default: per piece
        calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
        // Debug removed
      }
      
      // Create new global process object
      const newProcess = {
        ...selectedProcess,
        side: side,
        side_label: 'Pieza completa',
        unitPrice: basePrice, // Store the unit price
        veces: veces,
        price: calculatedPrice // Store the calculated total price
      };
      
      // Debug removed
      
      // Add process to global processes
      if (!this.product.data.global_processes) {
        this.product.data.global_processes = [];
      }
      this.product.data.global_processes.push(newProcess);
      
      // Reset selection
      this.selectedGlobalProcessId = null;
      
      // Emit update
      this.$emit('update:global-processes', this.product.data.global_processes);
      
      // Notify parent that pricing needs to be recalculated
      this.$emit('global-process-added', {
        processId: newProcess.id,
        price: calculatedPrice
      });
      this.$nextTick(() => this.initializeTooltips());
    },
    
    removeGlobalProcess(index) {
      if (this.product.data.global_processes) {
        this.product.data.global_processes.splice(index, 1);
        this.$emit('update:global-processes', this.product.data.global_processes);
      }
      this.$nextTick(() => this.initializeTooltips());
    },
    
    getSideLabel(side) {
      const labels = {
        front: 'Frente',
        back: 'Reverso',
        both: 'Ambas'
      };
      return labels[side] || side;
    },
    

    
    getProcessCalculationInfo(process) {
      const quantity = this.product.data.general_info.quantity || 1;
      const unitStr = typeof process.unit === 'string'
        ? process.unit
        : (process.unit && process.unit.name || process.unit && process.unit.abbreviation || '');
      
      if (unitStr.toLowerCase().includes('millar') || unitStr.toLowerCase().includes('mil')) {
        return `${quantity} pzas ÷ 1000 = ${(quantity / 1000).toFixed(3)} millares`;
      } else if (unitStr.toLowerCase().includes('pieza') || unitStr.toLowerCase().includes('pza')) {
        return `${quantity} pzas`;
      } else {
        return `${quantity} pzas`;
      }
    },
    
    onExtraSelect(selectedOption) {
      if (!selectedOption) return;
      
      // Reset quantity to 1 when selecting a new extra
      this.extraQuantity = 1;
    },
    
    addExtra() {
      if (!this.selectedExtraId || this.extraQuantity <= 0) {
        return;
      }
      
      // selectedExtraId is now the full object, so we can use it directly
      const selectedExtra = this.selectedExtraId;
      
      if (!selectedExtra) {
        return;
      }
      
      // Create new extra object
      const newExtra = {
        ...selectedExtra,
        quantity: this.extraQuantity,
        total_price: (selectedExtra.unit_price || selectedExtra.price) * this.extraQuantity
      };
      
      // Add extra to extras array
      if (!this.product.data.extras) {
        this.product.data.extras = [];
      }
      this.product.data.extras.push(newExtra);
      
      // Reset selection
      this.selectedExtraId = null;
      this.extraQuantity = 1;
      
      // Emit update
      this.$emit('update:extras', this.product.data.extras);
      this.$nextTick(() => this.initializeTooltips());
    },
    
    removeExtra(index) {
      if (this.product.data.extras) {
        this.product.data.extras.splice(index, 1);
        this.$emit('update:extras', this.product.data.extras);
      }
      this.$nextTick(() => this.initializeTooltips());
    },
    
    updateGlobalProcessCalculations(index) {
      const process = this.product.data.global_processes[index];
      if (!process) return;
      
      // Validar valores
      const veces = Math.max(1, process.veces || 1);
      const unitPrice = Math.max(0, process.unitPrice || 0);
      const productQuantity = this.product.data.general_info.quantity || 1;
      
      // Actualizar valores
      process.veces = veces;
      process.unitPrice = unitPrice;
      
      // Recalcular precio total
      const side = process.side || 'both';
      const sideMultiplier = side === 'both' ? 2 : 1;
      
      // Calcular precio total basado en el tipo de unidad
      let calculatedPrice = unitPrice;
      const unitStr = typeof process.unit === 'string'
        ? process.unit
        : (process.unit && process.unit.name || process.unit && process.unit.abbreviation || '');
      
      if (unitStr.toLowerCase().includes('pieza') || unitStr.toLowerCase().includes('pza')) {
        // Per piece
        calculatedPrice = unitPrice * productQuantity * veces * sideMultiplier;
      } else if (unitStr.toLowerCase().includes('millar') || unitStr.toLowerCase().includes('mil')) {
        // Per thousand
        calculatedPrice = (unitPrice * productQuantity * veces * sideMultiplier) / 1000;
      } else {
        // Default: per piece
        calculatedPrice = unitPrice * productQuantity * veces * sideMultiplier;
      }
      
      process.price = calculatedPrice;
      
      // Emitir actualización
      this.$emit('update:global-processes', this.product.data.global_processes);
      
      // Notificar que los precios necesitan ser recalculados
      this.$emit('global-process-updated', {
        processId: process.id,
        price: calculatedPrice
      });
    },
    
    updateExtraCalculations(index) {
      const extra = this.product.data.extras[index];
      if (!extra) return;
      
      // Validar valores
      const quantity = Math.max(1, extra.quantity || 1);
      const unitPrice = Math.max(0, extra.unit_price || 0);
      
      // Actualizar valores
      extra.quantity = quantity;
      extra.unit_price = unitPrice;
      
      // Recalcular precio total
      const calculatedPrice = unitPrice * quantity;
      extra.total_price = calculatedPrice;
      
      // Emitir actualización
      this.$emit('update:extras', this.product.data.extras);
      
      // Notificar que los precios necesitan ser recalculados
      this.$emit('extra-updated', {
        extraId: extra.id,
        price: calculatedPrice
      });
    },
    
    updateIncludeInSubtotal() {
      this.$emit('update:include-extras-in-subtotal', this.includeInSubtotal);
    }
  }
};
</script>

<style scoped lang="scss">
.additional-costs-tab-v2 {
    /* Ocultar tooltip de ayuda "Press enter to select" del multiselect (producción) */
    :deep(.multiselect__option--highlight::after) {
      display: none !important;
    }

    :deep(.multiselect__option--highlight .multiselect__option--selected) {
      display: none !important;
    }

  /* Estilos para bordes sutiles */
  .subtle-border {
    border-color: #6c757d !important; /* Color gris sutil como el selector */
  }
  
  .subtle-border-top {
    border-top-color: #6c757d !important; /* Color gris sutil para separadores */
  }
  
  /* Estilos para esquinas circulares */
  .rounded-bottom {
    border-bottom-left-radius: 0.5rem !important;
    border-bottom-right-radius: 0.5rem !important;
  }
  
  /* Asegurar que el último elemento del contenedor tenga esquinas circulares */
  .process-container > *:last-child {
    border-bottom-left-radius: 0.5rem !important;
    border-bottom-right-radius: 0.5rem !important;
  }
  
  .process-item {
    .process-container {
      background: var(--bs-body-bg);
      border: 1px solid #6c757d; /* Borde sutil en lugar de var(--bs-border-color) */
      border-radius: 0.5rem;
      overflow: hidden; /* Cambiado de visible a hidden para mantener bordes continuos */
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    }
    
    /* Asegurar que el fondo sea negro puro */
    .global-processes-list {
      background: #000000;
      padding: 1rem;
      border-radius: 0.5rem;
    }
    
    .process-header {
      background: var(--bs-body-bg);
    }
    
    .process-name {
      font-weight: 600;
      color: var(--bs-body-color);
    }
    
      .process-info {
        flex: 1 1 auto !important;
      }
    
    .process-description-column {
      overflow: hidden;
      
      .process-name {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        max-width: 100%;
        display: block;
      }
    }
    
    .price-column {
      font-weight: 600;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  
  .extra-item {
    .extra-container {
      background: var(--bs-body-bg);
      border: 1px solid #6c757d; /* Borde sutil en lugar de var(--bs-border-color) */
      border-radius: 0.5rem;
      overflow: hidden; /* Cambiado de visible a hidden para mantener bordes continuos */
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    }
    
    /* Asegurar que el fondo sea negro puro */
    .extras-list {
      background: #000000;
      padding: 1rem;
      border-radius: 0.5rem;
    }
    
    .extra-header {
      background: var(--bs-body-bg);
    }
    
    .extra-name {
      font-weight: 600;
      color: var(--bs-body-color);
    }
    
    .extra-info {
      flex: 1 1 auto !important;
    }
    
    .extra-description-column {
      overflow: hidden;
      
      .extra-name {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        max-width: 100%;
        display: block;
      }
    }
    
    .price-column {
      font-weight: 600;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  
  .form-check {
    .form-check-input:checked {
      background-color: var(--cotalo-green);
      border-color: var(--cotalo-green);
    }
  }
}

// Responsive adjustments
@media (max-width: 768px) {
  .additional-costs-tab-v2 {
    .process-item,
    .extra-item {
      .d-flex {
        flex-direction: column;
        align-items: flex-start !important;
        gap: 1rem;
      }
      
      .text-end {
        text-align: left !important;
      }
    }
  }
}
</style> 