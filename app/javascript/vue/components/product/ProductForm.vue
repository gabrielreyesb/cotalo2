<template>
  <div class="product-form overflow-auto">
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
        <div class="col-12 col-lg-9">
          <div class="green-accent-panel">
            <div class="card">
              <div class="card-body p-0">
                <ul class="nav nav-tabs" id="product-tabs">
                  <li class="nav-item">
                    <a class="nav-link" :class="{ active: activeTab === 'general' }" 
                       href="#" @click.prevent="setActiveTab('general')">
                      <i class="fa fa-info-circle me-1"></i> {{ translations.tabs.general }}
                    </a>
                  </li>
                  <li class="nav-item">
                    <a class="nav-link" :class="{ active: activeTab === 'materials' }" 
                       href="#" @click.prevent="setActiveTab('materials')">
                      <i class="fa fa-cubes me-1"></i> {{ translations.tabs.materials }}
                    </a>
                  </li>
                  <li class="nav-item">
                    <a class="nav-link" :class="{ active: activeTab === 'processes' }" 
                       href="#" @click.prevent="setActiveTab('processes')">
                      <i class="fa fa-cogs me-1"></i> {{ translations.tabs.processes }}
                    </a>
                  </li>
                  <li class="nav-item">
                    <a class="nav-link" :class="{ active: activeTab === 'extras' }" 
                       href="#" @click.prevent="setActiveTab('extras')">
                      <i class="fa fa-plus-circle me-1"></i> {{ translations.tabs.extras }}
                    </a>
                  </li>
                </ul>
                
                <div class="tab-content">
                  <!-- General Tab -->
                  <div v-if="activeTab === 'general' && product" class="tab-pane active">
                    <general-tab 
                      :product="product" 
                      :is-new="isNew"
                      :translations="translations"
                      @update:product="updateProduct"
                      @create:product="createProduct"
                    />
                  </div>
                  
                  <!-- Materials Tab -->
                  <div v-if="activeTab === 'materials' && product" class="tab-pane active">
                    <materials-tab 
                      :product-materials="product && product.data && product.data.materials ? product.data.materials : []"
                      :available-materials="availableMaterials"
                      :comments="product && product.data && product.data.materials_comments ? product.data.materials_comments : ''"
                      :product-width="product && product.data && product.data.general_info ? product.data.general_info.width : 0"
                      :product-length="product && product.data && product.data.general_info ? product.data.general_info.length : 0"
                      :product-quantity="product && product.data && product.data.general_info ? product.data.general_info.quantity : 1"
                      :width-margin="userConfig.width_margin"
                      :length-margin="userConfig.length_margin"
                      :translations="translations"
                      @update:product-materials="updateMaterials"
                      @update:comments="updateMaterialsComments"
                      @update:materials-cost="updateMaterialsCost"
                      @material-calculation-changed="handleMaterialCalculationChanged"
                    />
                  </div>
                  
                  <!-- Processes Tab -->
                  <div v-if="activeTab === 'processes' && product" class="tab-pane active">
                    <processes-tab
                      :product-processes-by-material="productProcessesByMaterial"
                      :available-processes="availableProcesses"
                      :comments="product && product.data && product.data.processes_comments ? product.data.processes_comments : ''"
                      :product-quantity="product && product.data && product.data.general_info ? product.data.general_info.quantity : 1"
                      :product-width="product && product.data && product.data.general_info ? product.data.general_info.width : 0"
                      :product-length="product && product.data && product.data.general_info ? product.data.general_info.length : 0"
                      :total-sheets="calculateTotalSheets()"
                      :total-square-meters="calculateTotalSquareMeters()"
                      :product-materials="product && product.data && product.data.materials ? product.data.materials : []"
                      :translations="translations"
                      @update:product-processes-by-material="val => productProcessesByMaterial = val"
                      @update:comments="updateProcessesComments"
                      @update:processes-cost="updateProcessesCost"
                    />
                  </div>
                  
                  <!-- Extras Tab -->
                  <div v-if="activeTab === 'extras' && product" class="tab-pane active">
                    <extras-tab 
                      :product-extras="product && product.data && product.data.extras ? product.data.extras : []"
                      :available-extras="availableExtras"
                      :comments="product && product.data && product.data.extras_comments ? product.data.extras_comments : ''"
                      :product-quantity="product && product.data && product.data.general_info ? product.data.general_info.quantity : 1"
                      :include-extras-in-subtotal="product && product.data && product.data.include_extras_in_subtotal !== undefined ? product.data.include_extras_in_subtotal : true"
                      :translations="translations"
                      @update:product-extras="updateExtras"
                      @update:comments="updateExtrasComments"
                      @update:include-extras-in-subtotal="updateIncludeExtrasInSubtotal"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Right Column - Pricing Panel -->
        <div class="col-12 col-lg-3 mt-3 mt-lg-0 ps-lg-4">
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
import GeneralTab from './GeneralTab.vue'
import PricingTab from './PricingTab.vue'
import ProcessesTab from './ProcessesTab.vue'
import MaterialsTab from './MaterialsTab.vue'
import ExtrasTab from './ExtrasTab.vue'

export default {
  name: 'ProductForm',
  components: {
    ExtrasTab,
    GeneralTab,
    PricingTab,
    ProcessesTab,
    MaterialsTab
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
      activeTab: 'general',
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
      productProcessesByMaterial: {},
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
      
      if (['general', 'extras', 'processes', 'materials', 'pricing'].includes(tab)) {
        this.activeTab = tab;
        
        if (tab === 'pricing') {
          await this.ensurePricingUpdated();
          this.recalculatePricing();
          this.suggestedMargin = await this.calculateSuggestedMargin();
          this.$nextTick(() => {
            this.$forceUpdate();
          });
        }
      } else if (!this.productId) {
        return;
      } else {
        this.activeTab = tab;
      }
    },
    groupProcessesByMaterial(processes) {
      const grouped = {};
      if (!Array.isArray(processes)) return grouped;
      
      processes.forEach(process => {
        // Try different possible property names for materialId
        const materialId = process.materialId || process.material_id;
        
        if (!materialId) {
          return;
        }
        
        if (!grouped[materialId]) grouped[materialId] = [];
        grouped[materialId].push(process);
      });
      
      return grouped;
    },
    async fetchProduct() {
      if (!this.productId) {
        // For new product, initialize with empty structure
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
            processes: [],
            extras: [],
            extras_comments: '',
            processes_comments: '',
            pricing: {}
          };
        }
        // Ensure pricing object exists
        if (!this.product.data.pricing) {
          this.product.data.pricing = { ...this.defaultPricing };
        }
        // Only set margin_percentage if it is undefined or null
        if (
          this.product.data.pricing.margin_percentage === undefined ||
          this.product.data.pricing.margin_percentage === null
        ) {
          const suggested = await this.calculateSuggestedMargin();
          this.product.data.pricing.margin_percentage = suggested;
          this.suggestedMargin = suggested;
        } else {
          this.suggestedMargin = this.product.data.pricing.margin_percentage;
        }
        // After loading product, group processes by material
        this.productProcessesByMaterial = this.groupProcessesByMaterial(this.product.data.processes);
        // Do NOT call recalculatePricing or ensurePricingUpdated here
        // Let the UI show the backend value first
      } catch (error) {
        console.error('Error loading product:', error);
        window.showError(error.message);
      } finally {
        this.loading = false;
      }
    },
    async fetchUserConfig() {
      try {
        const response = await fetch('/api/v1/user_config', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to load user config: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Update user configuration values
        if (data) {
          // Use the waste_percentage directly from the app config
          this.userConfig.waste_percentage = data.waste_percentage;
          this.userConfig.width_margin = data.width_margin || 0;
          this.userConfig.length_margin = data.length_margin || 0;
          
          // Update default pricing with user config values
          this.defaultPricing.waste_percentage = data.waste_percentage;
        }
      } catch (error) {
        console.error('Error loading user config:', error);
        // Don't set default values, let the backend handle defaults
      }
    },
    initializeNewProduct() {
      try {
        // Initialize with empty structure for a new product
        this.product = {
          description: '',
          data: {
            name: '',
            sku: '',
            quantity: 1,
            general_info: {},
            extras: [],
            extras_comments: '',
            processes: [],
            processes_comments: '',
            materials: [],
            materials_comments: '',
            pricing: {
              ...this.defaultPricing,
              waste_percentage: this.userConfig.waste_percentage,
              margin_percentage: 0
            }
          }
        };
        
        // Set loading to false for new products
        this.loading = false;
      } catch (error) {
        console.error('Error initializing new product:', error);
        window.showError(error.message);
      }
    },
    async createProduct(productData) {
      try {
        this.saving = true;
        
        const response = await fetch('/api/v1/products', {
          method: 'POST',
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
        
        if (!response.ok) {
          throw new Error(`Failed to create product: ${response.status} ${response.statusText}`);
        }
        
        const createdProduct = await response.json();
        
        // Show success message and redirect to products index after successful save
        window.showSuccess(`Producto ${this.isNew ? 'creado' : 'actualizado'} exitosamente`);
        
        // Wait for a short duration to allow the user to see the toast notification
        setTimeout(() => {
          window.location.href = '/products';
        }, 3000); // 3 second delay

      } catch (error) {
        console.error('Error creating product:', error);
        this.error = error.message;
      } finally {
        this.saving = false;
      }
    },
    async updateProduct(updatePayload) {
      try {
        // Calculate dimension changes BEFORE merge
        const oldQuantity = this.product.data.general_info?.quantity;
        const oldWidth = this.product.data.general_info?.width;
        const oldLength = this.product.data.general_info?.length;

        // Use optional chaining on updatePayload
        const newQuantity = updatePayload.data?.general_info?.quantity;
        const newWidth = updatePayload.data?.general_info?.width;
        const newLength = updatePayload.data?.general_info?.length;

        // Only consider it changed if the new value is defined and different
        const quantityChanged = newQuantity !== undefined && oldQuantity !== newQuantity;
        const widthChanged = newWidth !== undefined && oldWidth !== newWidth;
        const lengthChanged = newLength !== undefined && oldLength !== newLength;

        // Simplified State Merge
        if (updatePayload.description !== undefined) {
          this.product.description = updatePayload.description;
        }
        if (updatePayload.data && updatePayload.data.general_info) {
          this.product.data.general_info = {
            ...this.product.data.general_info, 
            ...updatePayload.data.general_info
          };

          // Update legacy quantity if present in the payload
          if (updatePayload.data.general_info.quantity !== undefined) {
            this.product.data.quantity = updatePayload.data.general_info.quantity;
          }
        }
        
        // If quantity, width, or length changed, trigger recalculations
        if (quantityChanged || widthChanged || lengthChanged) {
          if (this.product.data.materials && this.product.data.materials.length > 0) {
            const updatedMaterials = this.product.data.materials.map(material => ({
              ...material,
              _needsRecalculation: true
            }));
            this.updateMaterials(updatedMaterials);
          }
          if (this.product.data.processes && this.product.data.processes.length > 0) {
            const updatedProcesses = this.product.data.processes.map(process => ({
              ...process,
              _needsRecalculation: true
            }));
            this.updateProcesses(updatedProcesses);
          }
          if (this.product.data.extras && this.product.data.extras.length > 0) {
            const updatedExtras = this.product.data.extras.map(extra => ({
              ...extra,
              _needsRecalculation: true
            }));
            this.updateExtras(updatedExtras);
          }
          this.ensurePricingUpdated();
        }
        
      } catch (error) {
        console.error('Error in updateProduct:', error);
      } 
    },
    async updateMaterials(materials) {
      if (!this.product || !this.product.data) return;
      
      // Ensure each material has a quantity field
      materials = materials.map(material => ({
        ...material,
        quantity: material.totalSheets || material.piecesPerMaterial || material.total_quantity || 1
      }));
      
      // Check if there's any material with the needsRecalculation flag
      const needsRecalculation = materials.some(material => material._needsRecalculation);
      
      if (needsRecalculation) {
        // Get the current dimensions and quantity from the product
        const productWidth = this.product.data.general_info?.width || 0;
        const productLength = this.product.data.general_info?.length || 0;
        const productQuantity = this.product.data.general_info?.quantity || 1;
        
        // Add width and length margins to the product dimensions
        const effectiveProductWidth = productWidth + this.userConfig.width_margin;
        const effectiveProductLength = productLength + this.userConfig.length_margin;
        
        // Manually calculate each material's values based on current dimensions and quantity
        materials = materials.map(material => {
          // Skip materials that don't need recalculation
          if (!material._needsRecalculation) return material;
          
          // Calculate pieces per material
          const materialWidth = parseFloat(material.ancho) || 0;
          const materialLength = parseFloat(material.largo) || 0;
          
          let piecesPerMaterial = 0;
          if (materialWidth > 0 && materialLength > 0 && effectiveProductWidth > 0 && effectiveProductLength > 0) {
            // Calculate how many pieces fit horizontally and vertically
            const horizontalPieces = Math.floor(materialWidth / effectiveProductWidth);
            const verticalPieces = Math.floor(materialLength / effectiveProductLength);
            
            // Try the other orientation as well
            const horizontalPiecesAlt = Math.floor(materialWidth / effectiveProductLength);
            const verticalPiecesAlt = Math.floor(materialLength / effectiveProductWidth);
            
            // Use the orientation that fits more pieces
            piecesPerMaterial = Math.max(
              horizontalPieces * verticalPieces, 
              horizontalPiecesAlt * verticalPiecesAlt
            );
          }
          
          // Calculate total sheets needed
          const totalSheets = piecesPerMaterial > 0 ? Math.ceil(productQuantity / piecesPerMaterial) : 0;
          
          // Calculate total square meters
          const totalSquareMeters = totalSheets * (materialWidth * materialLength) / 10000; // convert cm² to m²
          
          // Calculate total price - based on square meters, not sheets
          const totalPrice = totalSquareMeters * (material.price || 0);
          
          return {
            ...material,
            quantity: totalSheets,
            piecesPerMaterial,
            totalSheets,
            totalSquareMeters,
            totalPrice,
            _needsRecalculation: undefined
          };
        });
      }
      
      // Update local materials data
      this.product.data.materials = materials;
      
      // Calculate the total cost of materials
      const materialsCost = materials.reduce((sum, material) => sum + (parseFloat(material.totalPrice) || 0), 0);
      
      // Update pricing data
      if (!this.product.data.pricing) {
        this.product.data.pricing = { ...this.defaultPricing };
      }
      
      // Update materials cost in pricing
      this.product.data.pricing.materials_cost = materialsCost;
      
      // Update pricing with new calculations
      await this.ensurePricingUpdated();
    },
    async updateProcesses(processes) {
      if (!this.product || !this.product.data) return;
      
      // Check if there's any process with the needsRecalculation flag
      const needsRecalculation = processes.some(process => process._needsRecalculation);
      
      if (needsRecalculation) {
        // Get the current quantity and calculate sheets/square meters
        const productQuantity = this.product.data.general_info?.quantity || 1;
        const totalSheets = this.calculateTotalSheets();
        const totalSquareMeters = this.calculateTotalSquareMeters();
                
        // Manually calculate each process's price based on current values
        processes = processes.map(process => {
          // Skip processes that don't need recalculation
          if (!process._needsRecalculation) return process;
          
          const basePrice = parseFloat(process.unitPrice) || 0;
          let calculatedPrice = basePrice;
          
          // Recalculate price based on unit type
          if (process.unit === 'pieza') {
            calculatedPrice = basePrice * productQuantity;
          } else if (process.unit === 'pliego') {
            calculatedPrice = basePrice * totalSheets;
          } else if (process.unit === 'mt2') {
            calculatedPrice = basePrice * totalSquareMeters;
          }
          
          return {
            ...process,
            price: calculatedPrice,
            _needsRecalculation: undefined // Remove the flag
          };
        });
      }
      
      // Update local processes data
      this.product.data.processes = processes;
      
      // Calculate the total cost of processes
      const processesCost = processes.reduce((sum, process) => sum + (parseFloat(process.price) || 0), 0);
      
      // Update pricing data
      if (!this.product.data.pricing) {
        this.product.data.pricing = { ...this.defaultPricing };
      }
      
      // Update processes cost in pricing
      this.product.data.pricing.processes_cost = processesCost;
      
      // Update pricing with new calculations
      await this.ensurePricingUpdated();
    },
    async updateExtras(extras) {
      if (!this.product || !this.product.data) return;
      
      // Update local extras data
      this.product.data.extras = extras;
      
      // Calculate total extras cost
      const extrasCost = extras.reduce((sum, extra) => {
        const price = parseFloat(extra.unit_price) || 0;
        const quantity = parseInt(extra.quantity) || 0;
        return sum + (price * quantity);
      }, 0);
      
      // Update pricing data
      if (!this.product.data.pricing) {
        this.product.data.pricing = { ...this.defaultPricing };
      }
      
      // Update extras cost in pricing
      this.product.data.pricing.extras_cost = extrasCost;
      
      // Update pricing with new calculations
      await this.ensurePricingUpdated();
    },
    async fetchAvailableExtras() {
      try {
        // Using the API path from routes
        const response = await fetch('/api/v1/extras', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        
        if (!response.ok) {
          throw new Error(`Failed to load available extras: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        this.availableExtras = data;
      } catch (error) {
        console.error('Error loading available extras:', error);
        this.availableExtras = []; // Ensure we have an empty array if the request fails
      }
    },
    async fetchAvailableProcesses() {
      try {
        const response = await fetch('/api/v1/manufacturing_processes', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to load available processes: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        this.availableProcesses = data;
      } catch (error) {
        console.error('Error loading available processes:', error);
        this.availableProcesses = []; // Ensure we have an empty array if the request fails
      }
    },
    async fetchAvailableMaterials() {
      try {
        const response = await fetch('/api/v1/materials', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to load available materials: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        this.availableMaterials = data;
      } catch (error) {
        console.error('Error loading available materials:', error);
        this.availableMaterials = []; // Ensure we have an empty array if the request fails
      }
    },
    updateMaterialsCost(cost) {
      if (!this.product || !this.product.data || !this.product.data.pricing) return;
      
      // Update pricing data
      this.product.data.pricing.materials_cost = cost;
      
      // Recalculate pricing
      this.recalculatePricing();
    },
    updateProcessesCost(cost) {
      if (!this.product || !this.product.data) return;
      
      // Ensure pricing object exists
      if (!this.product.data.pricing) {
        this.product.data.pricing = { ...this.defaultPricing };
      }
      
      // Update pricing data with the passed cost value (not recalculating)
      this.product.data.pricing.processes_cost = parseFloat(cost) || 0;
      
      // Recalculate total pricing
      this.recalculatePricing();
      
    },
    calculateTotalSheets() {
      // Calculate the total number of sheets needed based on materials
      if (!this.product || !this.product.data || !this.product.data.materials) return 0;
      
      return this.product.data.materials.reduce((sum, material) => {
        return sum + (parseInt(material.sheets) || 0);
      }, 0);
    },
    calculateTotalSquareMeters() {
      // Get the total square meters directly from the materials
      if (!this.product || !this.product.data || !this.product.data.materials) {
        return 0;
      }
      
      const totalSqMeters = this.product.data.materials.reduce((sum, material) => {
        // Use the pre-calculated totalSquareMeters property if available
        if (material.totalSquareMeters) {
          return sum + material.totalSquareMeters;
        } else {
          // Fallback to calculating if not available
          const width = parseFloat(material.ancho) || 0;
          const length = parseFloat(material.largo) || 0;
          const sheets = parseInt(material.sheets) || 0;
          
          // Square meters = (width in cm * length in cm) / 10000 * number of sheets
          const sqm = (width * length / 10000) * sheets;
          return sum + sqm;
        }
      }, 0);
      
      return totalSqMeters;
    },
    getSelectedMaterial() {
      // This method is no longer needed since we removed material selection
      return null;
    },
    async updateMaterialsComments(comments) {
      if (!this.product || !this.product.data) return;
      
      // Update locally
      this.product.data.materials_comments = comments;
      
      // If we have a productId, also update on the server
      if (this.productId) {
        try {
          const response = await fetch(`/api/v1/products/${this.productId}/update_materials_comments`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              materials_comments: comments
            })
          });
          
          if (!response.ok) {
            console.error('Failed to update materials comments');
          }
        } catch (error) {
          console.error('Error updating materials comments:', error);
        }
      }
    },
    async updateExtrasComments(comments) {
      if (!this.product || !this.product.data) return;
      
      // Update locally
      this.product.data.extras_comments = comments;
      
      // If we have a productId, also update on the server
      if (this.productId) {
        try {
          const response = await fetch(`/api/v1/products/${this.productId}/update_extras_comments`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              extras_comments: comments
            })
          });
          
          if (!response.ok) {
            console.error('Failed to update extras comments');
          }
        } catch (error) {
          console.error('Error updating extras comments:', error);
        }
      }
    },
    async recalculatePricing() {
      if (!this.product || !this.product.data || !this.product.data.pricing) {
        return;
      }
      const pricing = this.product.data.pricing;
      // Ensure waste_percentage and margin_percentage are set from user config if not already set
      if (!pricing.waste_percentage && pricing.waste_percentage !== 0) {
        pricing.waste_percentage = this.userConfig.waste_percentage;
      }
      // Calculate subtotal – ensure all values are numbers
      pricing.materials_cost = parseFloat(pricing.materials_cost) || 0;
      pricing.processes_cost = parseFloat(pricing.processes_cost) || 0;
      pricing.extras_cost = parseFloat(pricing.extras_cost) || 0;
      // Calculate subtotal based on whether extras should be included
      const includeExtrasInSubtotal = this.product.data.include_extras_in_subtotal !== undefined ? 
        this.product.data.include_extras_in_subtotal : true;
      const newSubtotal = pricing.materials_cost + pricing.processes_cost + 
        (includeExtrasInSubtotal ? pricing.extras_cost : 0);
      // If subtotal has changed significantly, recalculate margin
      if (Math.abs(pricing.subtotal - newSubtotal) > 0.01) {
        pricing.subtotal = newSubtotal;
        // Calculate waste
        pricing.waste_value = pricing.subtotal * (pricing.waste_percentage / 100);
        // Calculate new suggested margin (if new product or margin_percentage is undefined/null) and manualMarginOverride is false
        if (this.isNew || (pricing.margin_percentage === undefined || pricing.margin_percentage === null)) {
          if (!this.manualMarginOverride) {
            const newSuggestedMargin = await this.calculateSuggestedMargin();
            this.suggestedMargin = newSuggestedMargin;
            pricing.margin_percentage = newSuggestedMargin;
          }
        }
        pricing.subtotal = newSubtotal;
        // Calculate waste
        pricing.waste_value = pricing.subtotal * (pricing.waste_percentage / 100);
      }
      // Calculate subtotal with waste
      const subtotalWithWaste = pricing.subtotal + pricing.waste_value;
      // Get quantity from general_info if available, otherwise use product quantity or default to 1
      const quantity = 
        (this.product.data.general_info && this.product.data.general_info.quantity) || 
        this.product.data.quantity || 
        1;
      // Calculate price per piece before margin
      pricing.price_per_piece_before_margin = subtotalWithWaste / quantity;
      // Calculate margin
      pricing.margin_value = subtotalWithWaste * (pricing.margin_percentage / 100);
      // Calculate total price
      pricing.total_price = subtotalWithWaste + pricing.margin_value;
      // Calculate final price per piece
      pricing.final_price_per_piece = pricing.total_price / quantity;
    },
    async ensurePricingUpdated() {
      if (!this.product || !this.product.data || !this.product.data.pricing) {
        return;
      }
      const pricing = this.product.data.pricing;
      // Calculate subtotal – ensure all values are numbers
      pricing.materials_cost = parseFloat(pricing.materials_cost) || 0;
      pricing.processes_cost = parseFloat(pricing.processes_cost) || 0;
      pricing.extras_cost = parseFloat(pricing.extras_cost) || 0;
      // Calculate subtotal (based on whether extras are included)
      const includeExtrasInSubtotal = this.product.data.include_extras_in_subtotal !== undefined ? 
        this.product.data.include_extras_in_subtotal : true;
      const newSubtotal = pricing.materials_cost + pricing.processes_cost + (includeExtrasInSubtotal ? pricing.extras_cost : 0);
      pricing.subtotal = newSubtotal;
      // Calculate waste value
      pricing.waste_value = pricing.subtotal * (pricing.waste_percentage / 100);
      // Calculate price per piece before margin
      const quantity = (this.product.data.general_info && this.product.data.general_info.quantity) || this.product.data.quantity || 1;
      pricing.price_per_piece_before_margin = (newSubtotal + pricing.waste_value) / quantity;
      // Calculate suggested margin (if new product or margin_percentage is undefined/null) and manualMarginOverride is false
      if (this.isNew || (pricing.margin_percentage === undefined || pricing.margin_percentage === null)) {
        if (!this.manualMarginOverride) {
          const newSuggestedMargin = await this.calculateSuggestedMargin();
          this.suggestedMargin = newSuggestedMargin;
          pricing.margin_percentage = newSuggestedMargin;
        }
      }
      // Calculate margin value
      pricing.margin_value = (newSubtotal + pricing.waste_value) * (pricing.margin_percentage / 100);
      // Calculate total price
      pricing.total_price = (newSubtotal + pricing.waste_value) + pricing.margin_value;
      // Calculate final price per piece
      pricing.final_price_per_piece = pricing.total_price / quantity;
    },
    async savePricingProduct() {
      try {
        this.saving = true;
        
        // Convert grouped processes back to flat array before saving
        this.convertGroupedProcessesToFlat();
        
        // Validate product data before submission
        const validationErrors = this.validateProduct();
        if (validationErrors.length > 0) {
          // Show all validation errors using toast
          const errorMessage = validationErrors.join('\n');
          window.showError(errorMessage);
          return;
        }
        
        const productData = {
          description: this.product.description,
          data: this.product.data
        };

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

        let responseData;
        try {
          responseData = await response.json();
        } catch (e) {
          // If JSON parsing fails, create a basic error object
          responseData = {
            error: response.statusText || 'Error de servidor'
          };
        }

        if (!response.ok) {
          // Handle validation errors from the server
          if (response.status === 422 && responseData.errors) {
            const validationErrors = Array.isArray(responseData.errors) ? 
              responseData.errors : 
              Object.values(responseData.errors || {}).flat();
            
            throw new Error(validationErrors.join('\n'));
          }
          
          // Handle other types of errors
          throw new Error(
            responseData.error || 
            responseData.message || 
            `Error al ${this.isNew ? 'crear' : 'actualizar'} el producto`
          );
        }

        // Show success message and redirect to products index after successful save
        window.showSuccess(`Producto ${this.isNew ? 'creado' : 'actualizado'} exitosamente`);
        
        // Wait for a short duration to allow the user to see the toast notification
        setTimeout(() => {
          window.location.href = '/products';
        }, 3000); // 3 second delay

      } catch (error) {
        console.error(`Error ${this.isNew ? 'creating' : 'updating'} product:`, error);
        
        // Show error message using toast
        const errorMessage = error.message || 
          `Error al ${this.isNew ? 'crear' : 'guardar'} el producto. Por favor, intente de nuevo.`;
        window.showError(errorMessage);
      } finally {
        this.saving = false;
      }
    },
    validateProduct() {
      const errors = [];
      
      if (!this.product?.description?.trim()) {
        errors.push('La descripción es requerida');
        return errors;
      }
      
      const generalInfo = this.product?.data?.general_info;
      if (!generalInfo) {
        errors.push('La información general es requerida');
        return errors;
      }

      const quantity = parseFloat(generalInfo.quantity);
      if (!quantity || quantity <= 0) {
        errors.push('La cantidad debe ser mayor a 0');
      }

      const width = parseFloat(generalInfo.width);
      if (!width || width <= 0) {
        errors.push('El ancho debe ser mayor a 0');
      }

      const length = parseFloat(generalInfo.length);
      if (!length || length <= 0) {
        errors.push('El largo debe ser mayor a 0');
      }
      
      const materials = this.product?.data?.materials;
      if (!materials || materials.length === 0) {
        errors.push('Se requiere al menos un material');
      } else {
        materials.forEach((material, index) => {
          const materialId = material.material_id || material.id;
          if (!materialId) {
            errors.push(`Material ${index + 1}: Se debe seleccionar un material`);
          }

          const materialQuantity = 
            parseFloat(material.quantity) ||
            parseFloat(material.totalSheets) ||
            parseFloat(material.piecesPerMaterial) ||
            parseFloat(material.total_quantity) ||
            0;
          
          if (!materialQuantity || materialQuantity <= 0) {
            errors.push(`Material ${index + 1}: La cantidad debe ser mayor a 0`);
          }
        });
      }
      
      return errors;
    },
    async updateProcessesComments(comments) {
      if (!this.product || !this.product.data) return;
      
      // Update locally
      this.product.data.processes_comments = comments;
      
      // If we have a productId, also update on the server
      if (this.productId) {
        try {
          const response = await fetch(`/api/v1/products/${this.productId}/update_processes_comments`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              processes_comments: comments
            })
          });
          
          if (!response.ok) {
            console.error('Failed to update processes comments');
          }
        } catch (error) {
          console.error('Error updating processes comments:', error);
        }
      }
    },
    
    handleMaterialSelectedForProducts(materialId) {
      // This method is no longer needed since we removed material selection
      return;
    },
    
    handleMaterialCalculationChanged(eventData) {
      if (!this.product || !this.product.data) return;
      
      const materialIndex = this.product.data.materials.findIndex(m => m.id === eventData.materialId);
      if (materialIndex !== -1) {
        this.product.data.materials[materialIndex] = {
          ...this.product.data.materials[materialIndex],
          totalSheets: eventData.totalSheets,
          totalSquareMeters: eventData.totalSquareMeters,
          totalPrice: eventData.totalPrice
        };
      }
      
      if (eventData.materialId === this.product.data.selected_material_id && this.product.data.processes && this.product.data.processes.length > 0) {
        const processesNeedingRecalculation = this.product.data.processes.map(process => {
          return {
            ...process,
            _needsRecalculation: true
          };
        });
        
        this.updateProcesses(processesNeedingRecalculation);
      }
      
      if (eventData.needsPricingRecalculation) {
        this.recalculatePricing();
      }
    },
    
    handlePricingUpdate(updatedPricing) {
      if (!this.product || !this.product.data) return;
      
      // Detect if margin_percentage was changed manually
      if (
        updatedPricing.margin_percentage !== undefined &&
        updatedPricing.margin_percentage !== this.product.data.pricing.margin_percentage
      ) {
        this.manualMarginOverride = true;
      }

      // Update the pricing data with the new values
      this.product.data.pricing = {
        ...this.product.data.pricing,
        ...updatedPricing
      };
      
      // Recalculate pricing to update all derived values
      this.recalculatePricing();
      
      // Force update to ensure changes propagate
      this.$nextTick(() => {
        this.$forceUpdate();
      });
    },
    handleCancel() {
      window.location.href = '/products';
    },
    async calculateSuggestedMargin() {
      if (!this.product || !this.product.data || !this.product.data.pricing) {
        return 0;
      }
      
      const pricing = this.product.data.pricing;
      const totalBeforeMargin = pricing.subtotal + pricing.waste_value;
            
      try {
        // Fetch suggested margin from the API's calculate endpoint
        const response = await fetch(`/api/v1/price_margins/calculate?price=${totalBeforeMargin}`, {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to calculate margin: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        return parseFloat(data.margin_percentage) || 0;
        
      } catch (error) {
        console.warn('Margin calculation API not available, using default margin:', error);
        // Use a default margin based on the total price
        if (totalBeforeMargin <= 1000) return 30; // 30% for small orders
        if (totalBeforeMargin <= 5000) return 25; // 25% for medium orders
        return 20; // 20% for large orders
      }
    },
    async updateIncludeExtrasInSubtotal(value) {
      if (!this.product || !this.product.data) return;
      
      // Update locally
      this.product.data.include_extras_in_subtotal = value;
      
      // Recalculate pricing
      this.recalculatePricing();
      
      // If we have a productId, also update on the server
      if (this.productId) {
        try {
          const response = await fetch(`/api/v1/products/${this.productId}/update_include_extras_in_subtotal`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              include_extras_in_subtotal: value
            })
          });
          
          if (!response.ok) {
            console.error('Failed to update include extras in subtotal preference');
          }
        } catch (error) {
          console.error('Error updating include extras in subtotal preference:', error);
        }
      }
    },
    convertGroupedProcessesToFlat() {
      if (!this.product || !this.product.data) return;
      
      // Convert from grouped format (productProcessesByMaterial) to flat array
      const flatProcesses = [];
      
      for (const materialId in this.productProcessesByMaterial) {
        const processes = this.productProcessesByMaterial[materialId];
        for (const process of processes) {
          flatProcesses.push({
            ...process,
            materialId: parseInt(materialId)
          });
        }
      }
      
      this.product.data.processes = flatProcesses;
    },
  },
  // Add the created hook to initialize the component
  async created() {
    try {
      // Load user configuration first
      await this.fetchUserConfig();
      
      // Fetch product data if editing an existing product
      await this.fetchProduct();
      
      // Fetch available extras, processes, and materials in parallel
      await Promise.all([
        this.fetchAvailableExtras(),
        this.fetchAvailableProcesses(),
        this.fetchAvailableMaterials()
      ]);
      
    } catch (error) {
      console.error('Error initializing product form:', error);
      window.showError('Failed to initialize the form. Please try refreshing the page.');
    } finally {
      // Ensure loading is set to false when all initialization is complete
      this.loading = false;
    }
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
    // Clean up event listeners and observer
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
.product-form {
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

.product-form .tab-pane.active {
  border-left: none !important;
  border-bottom: none !important;
}

.product-form .tab-content,
.tab-content {
  border-left: none !important;
  border-bottom: none !important;
}
</style>