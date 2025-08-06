<template>
  <div class="product-form-v2 overflow-auto">
    <div v-if="loading" class="text-center my-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Loading...</span>
      </div>
      <p class="mt-2">Loading product data...</p>
    </div>
    
    <div v-else class="product-form-container">
      <div class="d-none">
        <button id="save-product-button" @click="savePricingProduct"></button>
        <button id="cancel-product-button" @click="handleCancel"></button>
      </div>

      <div class="row g-0">
        <!-- Left Column - Main Tabs -->
        <div class="col-12 col-lg-10">
          <div class="green-accent-panel">
            <div class="card">
              <div class="card-body p-0">
                <ul class="nav nav-tabs" id="product-tabs">
                  <li class="nav-item">
                    <a class="nav-link" :class="{ active: activeTab === 'product' }" 
                       href="#" @click.prevent="setActiveTab('product')">
                      <i class="fa fa-cube me-1"></i> Producto
                    </a>
                  </li>
                  <li class="nav-item">
                    <a class="nav-link" :class="{ active: activeTab === 'additional-costs' }" 
                       href="#" @click.prevent="setActiveTab('additional-costs')">
                      <i class="fa fa-plus-circle me-1"></i> Costos adicionales
                    </a>
                  </li>
                </ul>
                
                <div class="tab-content">
                  <!-- Product Tab -->
                  <div v-if="activeTab === 'product' && product" class="tab-pane active">
                    <product-tab-v2 
                      :product="product" 
                      :is-new="isNew"
                      :available-materials="availableMaterials"
                      :available-processes="availableProcesses"
                      :translations="translations"
                      :user-config="userConfig"
                      @update:product="updateProduct"
                      @update:materials="updateMaterials"
                      @update:processes="updateProcesses"
                      @material-calculation-changed="handleMaterialCalculationChanged"
                      @remove-material-with-processes="handleRemoveMaterialWithProcesses"
                    />
                  </div>
                  
                  <!-- Additional Costs Tab -->
                  <div v-if="activeTab === 'additional-costs' && product" class="tab-pane active">
                    <additional-costs-tab-v2 
                      :product="product"
                      :available-processes="availableProcesses"
                      :available-extras="availableExtras"
                      :translations="translations"
                      @update:global-processes="updateGlobalProcesses"
                      @update:extras="updateExtras"
                      @update:include-extras-in-subtotal="updateIncludeExtrasInSubtotal"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Column - Pricing Panel -->
        <div class="col-12 col-lg-2 mt-3 mt-lg-0 ps-lg-4">
          <div class="green-accent-panel pricing-panel">
            <div class="card">
              <div class="card-header text-white">
                <h5 class="mb-0">
                  <i class="fa fa-calculator me-2"></i>{{ translations.pricing.total_price }}
                </h5>
              </div>
              <div class="card-body p-0">
                <pricing-tab 
                  :pricing="product.data.pricing || defaultPricing"
                  :is-new="isNew"
                  :suggested-margin="suggestedMargin"
                  :translations="translations"
                  :user-config="userConfig"
                  @save:product="savePricingProduct"
                  @recalculate:pricing="ensurePricingUpdated"
                  @update:pricing="handlePricingUpdate"
                  @cancel="handleCancel"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import PricingTab from './PricingTab.vue'
import ProductTabV2 from './ProductTabV2.vue'
import AdditionalCostsTabV2 from './AdditionalCostsTabV2.vue'

export default {
  name: 'ProductFormV2',
  components: {
    PricingTab,
    ProductTabV2,
    AdditionalCostsTabV2
  },
  props: {
    productId: {
      type: [Number, String],
      default: null
    },
    isNew: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      product: null,
      loading: true,
      activeTab: 'product',
      saving: false,
      availableExtras: [],
      availableProcesses: [],
      availableMaterials: [],
      suggestedMargin: 0,
      userConfig: {
        waste_percentage: 0,
        width_margin: 0,
        length_margin: 0
      },
      defaultPricing: {
        materials_cost: 0,
        material_processes_cost: 0,
        global_processes_cost: 0,
        processes_cost: 0,
        extras_cost: 0,
        subtotal: 0,
        waste_percentage: 0,
        waste_value: 0,
        price_per_piece_before_margin: 0,
        margin_percentage: 0,
        margin_value: 0,
        total_price: 0,
        final_price_per_piece: 0
      },
      translations: JSON.parse(document.getElementById('product-form-app').dataset.translations),
      manualMarginOverride: false,
      // Recalculation queue system
      recalculationQueue: {
        materials: false,
        processes: false,
        extras: false,
        pricing: false
      },
      isRecalculating: false,
    };
  },
  computed: {
    apiToken() {
      const metaTag = document.querySelector('meta[name="csrf-token"]');
      return metaTag ? metaTag.content : null;
    }
  },
  methods: {
    async setActiveTab(tab) {
      if (event.target.closest('.product-form-container')) {
        event.preventDefault();
      }
      
      if (['product', 'additional-costs'].includes(tab)) {
        this.activeTab = tab;
        
        if (tab === 'additional-costs') {
          // Ensure pricing is up to date when switching to additional costs
          await this.ensurePricingUpdated();
          this.suggestedMargin = await this.calculateSuggestedMargin();
          this.$nextTick(() => {
            this.$forceUpdate();
          });
        }
      }
    },

    // Initialize new product with default structure
    initializeNewProduct() {
      this.product = {
        id: null,
        description: '',
        data: {
          general_info: {
            width: 1,
            length: 1,
            inner_measurements: '',
            quantity: 1,
            comments: ''
          },
          materials: [],
          global_processes: [], // New structure for global processes
          extras: [],
          pricing: { ...this.defaultPricing }
        }
      };
    },

    // Fetch product data
    async fetchProduct() {
      if (!this.productId) {
        this.initializeNewProduct();
        return;
      }
      
      try {
        this.loading = true;
        const response = await fetch(`/api/v1/products/${this.productId}`, {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to load product: ${response.status} ${response.statusText}`);
        }
        
        this.product = await response.json();
        
        // Ensure data structure exists
        if (!this.product.data) {
          this.product.data = {
            general_info: {},
            materials: [],
            global_processes: [],
            extras: [],
            pricing: {}
          };
        }
        
        // Ensure pricing object exists
        if (!this.product.data.pricing) {
          this.product.data.pricing = { ...this.defaultPricing };
        }
        
        // Migrate old processes structure to new structure
        this.migrateProcessesStructure();
        
      } catch (error) {
        console.error('Error fetching product:', error);
        window.showError('Failed to load product data. Please try refreshing the page.');
      } finally {
        this.loading = false;
      }
    },

    // Migrate old processes structure to new V2 structure
    migrateProcessesStructure() {
      if (!this.product.data.processes) return;
      
      const oldProcesses = this.product.data.processes;
      const materialProcesses = [];
      const globalProcesses = [];
      
      oldProcesses.forEach(process => {
        if (process.materialId) {
          materialProcesses.push(process);
        } else {
          globalProcesses.push(process);
        }
      });
      
      // Group material processes by material
      const processesByMaterial = {};
      materialProcesses.forEach(process => {
        const materialId = process.materialId;
        if (!processesByMaterial[materialId]) {
          processesByMaterial[materialId] = [];
        }
        processesByMaterial[materialId].push(process);
      });
      
      // Update materials with their processes
      this.product.data.materials.forEach(material => {
        const materialId = material.materialInstanceId || material.id;
        material.processes = processesByMaterial[materialId] || [];
      });
      
      // Set global processes
      this.product.data.global_processes = globalProcesses;
      
      // Remove old processes array
      delete this.product.data.processes;
    },

    // Fetch available data
    async fetchAvailableData() {
      try {
        await Promise.all([
          this.fetchAvailableExtras(),
          this.fetchAvailableProcesses(),
          this.fetchAvailableMaterials()
        ]);
      } catch (error) {
        console.error('Error fetching available data:', error);
        window.showError('Failed to load available data. Please try refreshing the page.');
      }
    },

    async fetchAvailableExtras() {
      const response = await fetch('/api/v1/extras', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });
      
      if (response.ok) {
        this.availableExtras = await response.json();
      }
    },

    async fetchAvailableProcesses() {
      const response = await fetch('/api/v1/manufacturing_processes', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });
      
      if (response.ok) {
        this.availableProcesses = await response.json();
      }
    },

    async fetchAvailableMaterials() {
      const response = await fetch('/api/v1/materials', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });
      
      if (response.ok) {
        this.availableMaterials = await response.json();
      }
    },

    // Fetch user configuration
    async fetchUserConfig() {
      try {
        const response = await fetch('/api/v1/user_config', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (response.ok) {
          const config = await response.json();
          
          this.userConfig = {
            waste_percentage: parseFloat(config.waste_percentage) || 0.0,
            width_margin: config.width_margin || 0,
            length_margin: config.length_margin || 0
          };
        }
      } catch (error) {
        console.error('Error fetching user config:', error);
      }
    },

    // Update methods
    updateProduct(updatedProduct) {
      this.product = { ...this.product, ...updatedProduct };
    },

    updateMaterials(materials) {
      this.product.data.materials = materials;
      this.markForRecalculation('materials');
      // Forzar recálculo inmediato
      this.$nextTick(() => {
        this.ensurePricingUpdated();
      });
    },

    updateProcesses(processesByMaterial) {
      // Update processes for each material
      this.product.data.materials.forEach(material => {
        const materialId = material.materialInstanceId || material.id;
        material.processes = processesByMaterial[materialId] || [];
      });
      this.markForRecalculation('processes');
    },

    updateGlobalProcesses(globalProcesses) {
      this.product.data.global_processes = globalProcesses;
      this.markForRecalculation('processes');
      // Forzar recálculo inmediato del pricing
      this.$nextTick(() => {
        this.ensurePricingUpdated();
      });
    },

    updateExtras(extras) {
      this.product.data.extras = extras;
      this.markForRecalculation('extras');
    },

    updateIncludeExtrasInSubtotal(value) {
      this.product.data.include_extras_in_subtotal = value;
      this.markForRecalculation('pricing');
    },

    // Event handlers
    handleMaterialCalculationChanged(event) {
      // Solo marcar materiales para recálculo si el evento específicamente lo indica
      if (event.needsPricingRecalculation) {
        this.markForRecalculation('materials');
      }
      
      // Si el evento indica que necesita recálculo de procesos, marcarlo también
      if (event.needsProcessRecalculation) {
        this.markForRecalculation('processes');
      }
    },

    handleRemoveMaterialWithProcesses(event) {
      const { materialId, materialIndex, processesToRemove } = event;
      
      // Remove the material
      this.product.data.materials.splice(materialIndex, 1);
      
      // Emit updates
      this.$emit('update:product-materials', this.product.data.materials);
      this.markForRecalculation('materials');
    },

    // Pricing methods
    async ensurePricingUpdated() {
      try {
        this.isRecalculating = true;
        
        // Calculate materials cost
        const materialsCost = this.calculateMaterialsCost();
        
        // Calculate processes costs separately
        const materialProcessesCost = this.calculateMaterialProcessesCost();
        const globalProcessesCost = this.calculateGlobalProcessesCost();
        const processesCost = materialProcessesCost + globalProcessesCost;
        
        // Calculate extras cost
        const extrasCost = this.calculateExtrasCost();
        
        // Calculate subtotal
        const includeExtrasInSubtotal = this.product.data.include_extras_in_subtotal !== false;
        const subtotal = materialsCost + processesCost + (includeExtrasInSubtotal ? extrasCost : 0);
        
        // Update pricing
        this.product.data.pricing = {
          ...this.product.data.pricing,
          materials_cost: materialsCost,
          material_processes_cost: materialProcessesCost,
          global_processes_cost: globalProcessesCost,
          processes_cost: processesCost,
          extras_cost: extrasCost,
          subtotal: subtotal
        };
        
        // Calculate waste and margin
        await this.calculateWasteAndMargin();
        
      } finally {
        this.isRecalculating = false;
      }
    },

    calculateMaterialsCost() {
      if (!this.product || !this.product.data || !this.product.data.materials) return 0;
      return this.product.data.materials.reduce((sum, material) => {
        // Solo el precio del material (sin procesos)
        const materialPrice = parseFloat(material.totalPrice) || 0;
        return sum + materialPrice;
      }, 0);
    },

    calculateProcessesCost() {
      const materialProcessesCost = this.calculateMaterialProcessesCost();
      const globalProcessesCost = this.calculateGlobalProcessesCost();
      return materialProcessesCost + globalProcessesCost;
    },

    calculateMaterialProcessesCost() {
      let total = 0;
      
      // Procesos de materiales
      if (this.product && this.product.data && this.product.data.materials) {
        this.product.data.materials.forEach(material => {
          if (material.processes) {
            material.processes.forEach(process => {
              total += parseFloat(process.price) || 0;
            });
          }
        });
      }
      
      return total;
    },

    calculateGlobalProcessesCost() {
      let total = 0;
      
      // Procesos globales
      if (this.product && this.product.data && this.product.data.global_processes) {
        this.product.data.global_processes.forEach(process => {
          const processPrice = parseFloat(process.price) || 0;
          total += processPrice;
        });
      }
      
      return total;
    },

    calculateExtrasCost() {
      if (!this.product || !this.product.data || !this.product.data.extras) return 0;
      return this.product.data.extras.reduce((sum, extra) => {
        const price = parseFloat(extra.unit_price) || 0;
        const quantity = parseInt(extra.quantity) || 0;
        return sum + (price * quantity);
      }, 0);
    },

    async calculateWasteAndMargin() {
      const pricing = this.product.data.pricing;
      const subtotal = pricing.subtotal;
      
      // Calculate waste
      const wastePercentage = pricing.waste_percentage || this.userConfig.waste_percentage || 0;
      const wasteValue = subtotal * (wastePercentage / 100);
      
      // Calculate price per piece before margin
      const quantity = this.product.data.general_info.quantity || 1;
      const pricePerPieceBeforeMargin = (subtotal + wasteValue) / quantity;
      
      // Calculate margin
      const marginPercentage = pricing.margin_percentage || await this.calculateSuggestedMargin();
      const marginValue = (subtotal + wasteValue) * (marginPercentage / 100);
      
      // Calculate total
      const totalPrice = subtotal + wasteValue + marginValue;
      const finalPricePerPiece = totalPrice / quantity;
      
      // Update pricing
      Object.assign(pricing, {
        waste_value: wasteValue,
        price_per_piece_before_margin: pricePerPieceBeforeMargin,
        margin_percentage: marginPercentage,
        margin_value: marginValue,
        total_price: totalPrice,
        final_price_per_piece: finalPricePerPiece
      });
    },

    async calculateSuggestedMargin() {
      const pricing = this.product.data.pricing;
      const totalBeforeMargin = pricing.subtotal + pricing.waste_value;
      
      try {
        const response = await fetch(`/api/v1/price_margins/calculate?price=${totalBeforeMargin}`, {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (response.ok) {
          const data = await response.json();
          return data.margin_percentage || 0;
        }
      } catch (error) {
        console.error('Error calculating suggested margin:', error);
      }
      
      return 0;
    },

    // Recalculate processes when material properties change
    recalculateProcesses() {
      if (!this.product || !this.product.data || !this.product.data.materials) return;
      
      const productQuantity = this.product.data.general_info?.quantity || 1;
      
      // Recalculate material processes
      this.product.data.materials.forEach(material => {
        if (material.processes) {
          material.processes.forEach(process => {
            const basePrice = parseFloat(process.unitPrice) || 0;
            const veces = parseInt(process.veces) || 1;
            const side = process.side || 'front';
            const sideMultiplier = side === 'both' ? 2 : 1;
            let calculatedPrice = basePrice;
            
            if (process.unit === 'pieza') {
              calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
            } else if (process.unit === 'pliego') {
              // Use totalSheets if available, otherwise calculate it safely
              const totalSheets = material.totalSheets || 0;
              calculatedPrice = basePrice * totalSheets * veces * sideMultiplier;
            } else if (process.unit === 'mt2') {
              // Per square meter - consider material type
              const isWeightBased = this.isWeightBasedMaterial(material);
              if (isWeightBased) {
                // For weight-based materials, use total weight (in kg) instead of square meters
                const totalWeightKg = (material.totalWeight || 0) / 1000;
                calculatedPrice = basePrice * totalWeightKg * veces * sideMultiplier;
              } else {
                // For area-based materials, use square meters
                const totalSquareMeters = material.totalSquareMeters || 0;
                calculatedPrice = basePrice * totalSquareMeters * veces * sideMultiplier;
              }
            }
            
            process.price = calculatedPrice;
          });
        }
      });
      
      // Recalculate global processes
      if (this.product.data.global_processes) {
        this.product.data.global_processes.forEach(process => {
          const basePrice = parseFloat(process.unitPrice) || 0;
          const veces = parseInt(process.veces) || 1;
          const side = process.side || 'front';
          const sideMultiplier = side === 'both' ? 2 : 1;
          let calculatedPrice = basePrice;
          
          if (process.unit === 'pieza') {
            calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
          } else {
            // Global processes are typically per piece - multiply by product quantity
            calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
          }
          
          process.price = calculatedPrice;
        });
      }
    },

    // Helper method to check if material is weight-based
    isWeightBasedMaterial(material) {
      if (!material.unit) return false;
      
      let unitName = '';
      let unitAbbr = '';
      
      // Handle both object and string unit formats
      if (typeof material.unit === 'string') {
        unitName = material.unit.toLowerCase();
        unitAbbr = material.unit.toLowerCase();
      } else if (material.unit && typeof material.unit === 'object') {
        unitName = (material.unit.name || '').toLowerCase();
        unitAbbr = (material.unit.abbreviation || '').toLowerCase();
      }
      
      // Check for weight units (exact matches to avoid false positives)
      const weightUnits = ['kg', 'g', 'gr', 'gramo', 'gramos', 'kilo', 'kilos', 'kilogramo', 'kilogramos'];
      const weightMatch = weightUnits.some(wu => unitName === wu || unitAbbr === wu);
      const grsMatch = unitName.includes('grs/m2') || unitAbbr.includes('grs/m2');
      
      return weightMatch || grsMatch;
    },

    // Recalculation system
    markForRecalculation(type) {
      this.recalculationQueue[type] = true;
      this.processRecalculationQueue();
    },

    async processRecalculationQueue() {
      if (this.isRecalculating) {
        return;
      }
      
      this.isRecalculating = true;
      
      try {
        if (this.recalculationQueue.materials) {
          this.recalculationQueue.materials = false;
        }
        
        if (this.recalculationQueue.processes) {
          this.recalculateProcesses();
          this.recalculationQueue.processes = false;
        }
        
        if (this.recalculationQueue.extras) {
          this.recalculationQueue.extras = false;
        }
        
        if (this.recalculationQueue.pricing) {
          this.recalculationQueue.pricing = false;
        }
        
        // Solo llamar ensurePricingUpdated una vez al final
        await this.ensurePricingUpdated();
      } finally {
        this.isRecalculating = false;
        
        // Check if there are more items in the queue
        if (Object.values(this.recalculationQueue).some(Boolean)) {
          this.$nextTick(() => {
            this.processRecalculationQueue();
          });
        }
      }
    },

    // Save and cancel methods
    async savePricingProduct() {
      if (this.saving) return;
      
      try {
        this.saving = true;
        
        // Ensure pricing is up to date
        await this.ensurePricingUpdated();
        
        // Convert to old format for API compatibility
        const productData = this.convertToApiFormat();
        
        const url = this.isNew ? '/api/v1/products' : `/api/v1/products/${this.productId}`;
        const method = this.isNew ? 'POST' : 'PUT';
        
        const response = await fetch(url, {
          method: method,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': this.apiToken,
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: JSON.stringify({
            product: productData
          })
        });
        
        if (response.ok) {
          const savedProduct = await response.json();
          window.showSuccess('Product saved successfully!');
          
          // Redirect to products list or edit page
          if (this.isNew) {
            window.location.href = `/products/${savedProduct.id}/edit`;
          }
        } else {
          const error = await response.json();
          window.showError(`Failed to save product: ${(error.errors && error.errors.join(', ')) || 'Unknown error'}`);
        }
      } catch (error) {
        console.error('Error saving product:', error);
        window.showError('Failed to save product. Please try again.');
      } finally {
        this.saving = false;
      }
    },

    convertToApiFormat() {
      // Convert V2 format back to API format for compatibility
      const apiData = {
        description: this.product.description,
        data: {
          general_info: this.product.data.general_info,
          materials: this.product.data.materials,
          extras: this.product.data.extras,
          pricing: this.product.data.pricing,
          include_extras_in_subtotal: this.product.data.include_extras_in_subtotal
        }
      };
      
      // Convert processes back to flat array
      const allProcesses = [];
      
      // Add material-specific processes
      this.product.data.materials.forEach(material => {
        if (material.processes) {
          material.processes.forEach(process => {
            allProcesses.push({
              ...process,
              materialId: material.materialInstanceId || material.id
            });
          });
        }
      });
      
      // Add global processes
      if (this.product.data.global_processes) {
        allProcesses.push(...this.product.data.global_processes);
      }
      
      apiData.data.processes = allProcesses;
      
      return apiData;
    },

    handleCancel() {
      if (confirm('Are you sure you want to cancel? All unsaved changes will be lost.')) {
        window.location.href = '/products';
      }
    },

    handlePricingUpdate(pricing) {
      this.product.data.pricing = { ...this.product.data.pricing, ...pricing };
    }
  },
  
  async created() {
    try {
      // Load user configuration first
      await this.fetchUserConfig();
      
      // Fetch product data if editing an existing product
      await this.fetchProduct();
      
      // Fetch available extras, processes, and materials in parallel
      await this.fetchAvailableData();
      
    } catch (error) {
      console.error('Error initializing product form:', error);
      window.showError('Failed to initialize the form. Please try refreshing the page.');
    } finally {
      this.loading = false;
    }
  },
  
  watch: {
    // Watch for changes in materials and their processes to trigger pricing updates
    // TEMPORARILY DISABLED - causing infinite loops
    // 'product.data.materials': {
    //   handler(newMaterials, oldMaterials) {
    //     // Always update pricing when materials change
    //     this.$nextTick(() => {
    //       this.ensurePricingUpdated();
    //     });
    //     
    //     // Additional check for process-specific changes
    //     if (newMaterials && oldMaterials) {
    //       const processesChanged = newMaterials.some((material, index) => {
    //         const oldMaterial = oldMaterials[index];
    //         if (!oldMaterial) return true;
    //         
    //         // Check if processes array length changed
    //         if ((material.processes || []).length !== (oldMaterial.processes || []).length) {
    //           return true;
    //         }
    //         
    //         // Check if any process price changed
    //         return (material.processes || []).some((process, processIndex) => {
    //           const oldProcess = oldMaterial.processes?.[processIndex];
    //           return !oldProcess || process.price !== oldProcess.price;
    //         });
    //       });
    //       
    //       if (processesChanged) {
    //         this.$nextTick(() => {
    //           this.ensurePricingUpdated();
    //         });
    //       }
    //     }
    //   },
    //   deep: true
    // },
    
    // Watch for changes in global processes
    // TEMPORARILY DISABLED - causing infinite loops
    // 'product.data.global_processes': {
    //   handler() {
    //     this.$nextTick(() => {
    //       this.ensurePricingUpdated();
    //     });
    //   },
    //   deep: true
    // },
    
    // Watch for changes in extras
    // TEMPORARILY DISABLED - causing infinite loops
    // 'product.data.extras': {
    //   handler() {
    //     this.$nextTick(() => {
    //       this.ensurePricingUpdated();
    //     });
    //   },
    //   deep: true
    // }
  },
  
  mounted() {
    // Connect to the top navigation bar buttons
    const topNavSaveButton = document.getElementById('save-product-button');
    const topNavCancelButton = document.querySelector('a[href="/products"]');

    if (topNavSaveButton) {
      topNavSaveButton.addEventListener('click', () => this.savePricingProduct());
    }
    if (topNavCancelButton) {
      topNavCancelButton.addEventListener('click', (e) => {
        e.preventDefault();
        this.handleCancel();
      });
    }
  },
  
  beforeDestroy() {
    // Clean up event listeners
    const topNavSaveButton = document.getElementById('save-product-button');
    const topNavCancelButton = document.querySelector('a[href="/products"]');

    if (topNavSaveButton) {
      topNavSaveButton.removeEventListener('click', () => this.savePricingProduct());
    }
    if (topNavCancelButton) {
      topNavCancelButton.removeEventListener('click', (e) => {
        e.preventDefault();
        this.handleCancel();
      });
    }
  }
};
</script>

<style scoped>
.product-form-v2 {
  position: relative;
  width: 100%;
}

.product-form-container {
  width: 100%;
}

.nav-tabs {
  margin: 0 !important;
  border-bottom: 1px solid #32383e;
  background-color: #1a1e21;
}

.card {
  border: 1px solid #32383e;
  border-radius: 4px;
  background-color: #1a1e21;
}

.tab-pane {
  border: none;
  padding: 1rem;
}

.pricing-panel {
  width: 100%;
}

/* Add padding to align pricing panel with tabs */
.pt-tabs {
  padding-top: 0;
}

@media (max-width: 768px) {
  .pt-tabs {
    padding-top: 1rem;
  }
}

.product-form-v2 .tab-pane.active {
  border-left: none !important;
  border-bottom: none !important;
}

.product-form-v2 .tab-content,
.tab-content {
  border-left: none !important;
  border-bottom: none !important;
}
</style> 