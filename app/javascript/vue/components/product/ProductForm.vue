<template>
  <div class="product-form h-100 overflow-auto">
    <div v-if="loading" class="text-center my-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Loading...</span>
      </div>
      <p class="mt-2">Loading product data...</p>
    </div>
    
    <div v-else-if="error" class="alert alert-danger my-5">
      <h4 class="alert-heading">Error loading form</h4>
      <p>{{ error }}</p>
      <hr>
      <p class="mb-0">Please try refreshing the page or contact support if the problem persists.</p>
    </div>
    
    <div v-else class="product-form-container">
      <ul class="nav nav-tabs mb-4" id="product-tabs">
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'general' }" 
             href="#" @click.prevent="setActiveTab('general')">
            <i class="fa fa-info-circle me-1"></i> Información general
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'materials' }" 
             href="#" @click.prevent="setActiveTab('materials')">
            <i class="fa fa-cubes me-1"></i> Materiales
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'processes' }" 
             href="#" @click.prevent="setActiveTab('processes')">
            <i class="fa fa-cogs me-1"></i> Procesos
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'extras' }" 
             href="#" @click.prevent="setActiveTab('extras')">
            <i class="fa fa-plus-circle me-1"></i> Extras
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'pricing' }" 
             href="#" @click.prevent="setActiveTab('pricing')">
            <i class="fa fa-calculator me-1"></i> Precio
          </a>
        </li>
      </ul>
      
      <div class="tab-content">
        <!-- General Tab -->
        <div v-if="activeTab === 'general' && product" class="tab-pane active">
          <general-tab 
            :product="product" 
            :is-new="isNew"
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
            :selected-material-id="product && product.data && product.data.selected_material_id ? product.data.selected_material_id : null"
            :width-margin="userConfig.width_margin"
            :length-margin="userConfig.length_margin"
            @update:product-materials="updateMaterials"
            @update:comments="updateMaterialsComments"
            @update:materials-cost="updateMaterialsCost"
            @material-selected-for-products="handleMaterialSelectedForProducts"
            @material-calculation-changed="handleMaterialCalculationChanged"
          />
        </div>
        
        <!-- Processes Tab -->
        <div v-if="activeTab === 'processes' && product" class="tab-pane active">
          <processes-tab 
            :product-processes="product && product.data && product.data.processes ? product.data.processes : []"
            :available-processes="availableProcesses"
            :comments="product && product.data && product.data.processes_comments ? product.data.processes_comments : ''"
            :product-quantity="product && product.data && product.data.general_info ? product.data.general_info.quantity : 1"
            :total-sheets="calculateTotalSheets()"
            :total-square-meters="calculateTotalSquareMeters()"
            :selected-material-id="product && product.data ? product.data.selected_material_id : null"
            :selected-material-data="getSelectedMaterial()"
            @update:product-processes="updateProcesses"
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
            @update:product-extras="updateExtras"
            @update:comments="updateExtrasComments"
          />
        </div>
        
        <!-- Pricing Tab -->
        <div v-if="activeTab === 'pricing' && product" class="tab-pane active">
          <pricing-tab 
            :pricing="product.data.pricing || defaultPricing"
            :is-new="!productId"
            @save:product="savePricingProduct"
            @recalculate:pricing="ensurePricingUpdated"
            @update:pricing="handlePricingUpdate"
            @cancel="handleCancel"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ExtrasTab from './ExtrasTab.vue';
import GeneralTab from './GeneralTab.vue';
import PricingTab from './PricingTab.vue';
import ProcessesTab from './ProcessesTab.vue';
import MaterialsTab from './MaterialsTab.vue';

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
      error: null,
      availableExtras: [],
      availableProcesses: [],
      availableMaterials: [],
      userConfig: {
        waste_percentage: 5,
        margin_percentage: 30,
        width_margin: 0,
        length_margin: 0
      },
      defaultPricing: {
        materials_cost: 0,
        processes_cost: 0,
        extras_cost: 0,
        subtotal: 0,
        waste_percentage: 5,
        waste_value: 0,
        price_per_piece_before_margin: 0,
        margin_percentage: 30,
        margin_value: 0,
        total_price: 0,
        final_price_per_piece: 0
      }
    };
  },
  computed: {
    apiToken() {
      const metaTag = document.querySelector('meta[name="csrf-token"]');
      return metaTag ? metaTag.content : null;
    }
  },
  methods: {
    setActiveTab(tab) {
      console.log(`Switching to ${tab} tab`);
      
      // Allow switching between general, extras, processes and pricing tabs even for new products
      // Only restrict other tabs if product doesn't exist (has no ID)
      if (['general', 'extras', 'processes', 'materials', 'pricing'].includes(tab)) {
        // These tabs are always accessible
        this.activeTab = tab;
        
        // If switching to pricing tab, ensure pricing is calculated
        if (tab === 'pricing') {
          console.log('Switching to pricing tab, preparing data');
          
          // First ensure all pricing values are up to date
          this.ensurePricingUpdated();
          
          // Then recalculate to make sure everything is consistent
          this.recalculatePricing();
          
          // Give components time to update before final calculations
          this.$nextTick(() => {
            // Force a final update to ensure everything is rendered correctly
            console.log('Forcing update after switching to pricing tab');
            this.$forceUpdate();
          });
        }
      } else if (!this.productId) {
        console.warn(`Cannot switch to ${tab} tab: no product ID`);
        return;
      } else {
        // Other tabs require a product ID
        this.activeTab = tab;
      }
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
        
      } catch (error) {
        console.error('Error loading product:', error);
        this.error = error.message;
      } finally {
        this.loading = false;
      }
    },
    async fetchUserConfig() {
      try {
        // Use the app_configs endpoint instead of product-specific endpoints
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
          this.userConfig.waste_percentage = data.waste_percentage || 5;
          this.userConfig.margin_percentage = data.margin_percentage || 30;
          this.userConfig.width_margin = data.width_margin || 0;
          this.userConfig.length_margin = data.length_margin || 0;
          
          // Update default pricing with user config values
          this.defaultPricing.waste_percentage = this.userConfig.waste_percentage;
          this.defaultPricing.margin_percentage = this.userConfig.margin_percentage;
        }
      } catch (error) {
        console.error('Error loading user config:', error);
        // Continue with default values
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
            extras: [],
            extras_comments: '',
            processes: [],
            processes_comments: '',
            materials: [],
            materials_comments: '',
            pricing: {
              ...this.defaultPricing,
              waste_percentage: this.userConfig.waste_percentage,
              margin_percentage: this.userConfig.margin_percentage
            }
          }
        };
        
        // Set loading to false for new products
        this.loading = false;
      } catch (error) {
        console.error('Error initializing new product:', error);
        this.error = error.message;
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
        
        // Redirect to the products index page instead of edit
        window.location.href = '/products';
      } catch (error) {
        console.error('Error creating product:', error);
        this.error = error.message;
      } finally {
        this.saving = false;
      }
    },
    async updateProduct(data) {
      try {
        this.saving = true;
        
        // Extract shouldRedirect flag
        const shouldRedirect = data.data?.shouldRedirect;
        
        // Create a clean version of the data without the shouldRedirect flag
        const cleanData = {
          ...data,
          data: {
            ...data.data,
            general_info: {
              ...data.data.general_info
            }
          }
        };
        delete cleanData.data.shouldRedirect;
        
        // Check if dimensions or quantity have changed
        const oldQuantity = this.product.data.general_info?.quantity;
        const oldWidth = this.product.data.general_info?.width;
        const oldLength = this.product.data.general_info?.length;
        
        const newQuantity = cleanData.data.general_info?.quantity;
        const newWidth = cleanData.data.general_info?.width;
        const newLength = cleanData.data.general_info?.length;
        
        const quantityChanged = oldQuantity !== newQuantity;
        const widthChanged = oldWidth !== newWidth;
        const lengthChanged = oldLength !== newLength;
        
        // Properly merge the data to prevent losing information between tabs
        if (cleanData && cleanData.data && cleanData.data.general_info) {
          // Make sure we don't lose the current data by doing a proper merge
          this.product = {
            ...this.product,
            description: cleanData.description,
            data: {
              ...this.product.data,
              general_info: {
                ...cleanData.data.general_info
              }
            }
          };
          
          // Ensure quantity is also updated in the main data object for backwards compatibility
          if (cleanData.data.general_info.quantity) {
            this.product.data.quantity = cleanData.data.general_info.quantity;
          }
        }
        
        // If quantity, width, or length changed, trigger recalculations
        if (quantityChanged || widthChanged || lengthChanged) {
          
          // Force a full recalculation of materials
          if (this.product.data.materials && this.product.data.materials.length > 0) {
            // Call the parent's update method which will trigger recalculation in MaterialsTab
            const updatedMaterials = this.product.data.materials.map(material => {
              return {
                ...material,
                // Force material to be recalculated by setting these properties
                _needsRecalculation: true
              };
            });
            
            // This will trigger recalculation via updateMaterials
            this.updateMaterials(updatedMaterials);
          }
          
          // Force a full recalculation of processes
          if (this.product.data.processes && this.product.data.processes.length > 0) {
            // Call the parent's update method which will trigger recalculation in ProcessesTab
            const updatedProcesses = this.product.data.processes.map(process => {
              return {
                ...process,
                // We don't need to change anything here, just ensure the object is new
                _needsRecalculation: true
              };
            });
            
            // This will trigger recalculation
            this.updateProcesses(updatedProcesses);
          }
          
          // Calculate extras in case quantity affects them
          if (this.product.data.extras && this.product.data.extras.length > 0) {
            const updatedExtras = this.product.data.extras.map(extra => {
              return {
                ...extra,
                _needsRecalculation: true
              };
            });
            
            this.updateExtras(updatedExtras);
          }
          
          // Always recalculate pricing
          this.ensurePricingUpdated();
        }
        
        // Only save to server if we have a product ID (not for new products)
        if (this.productId) {
          const response = await fetch(`/api/v1/products/${this.productId}`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              product: cleanData
            })
          });
          
          if (!response.ok) {
            throw new Error('Failed to update product');
          }
          
          const updatedProduct = await response.json();
          this.product = updatedProduct;
          
          // Redirect if shouldRedirect flag was set
          if (shouldRedirect) {
            window.location.href = '/products';
          }
        }
        
      } catch (error) {
        console.error('[ProductForm] Error updating product:', error);
      } finally {
        this.saving = false;
      }
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
      
      // Recalculate pricing
      this.recalculatePricing();
      
      // If we have a productId, update on the server
      if (this.productId) {
        try {
          this.saving = true;
          
          const response = await fetch(`/api/v1/products/${this.productId}/update_extras`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              extras: extras
            })
          });
          
          if (!response.ok) {
            throw new Error('Failed to update extras');
          }
          
          // Update the local data with the updated extras
          this.product.data.extras = await response.json();
          
          // Fetch the updated product with new pricing
          this.fetchProduct();
          
        } catch (error) {
          console.error('Error updating extras:', error);
        } finally {
          this.saving = false;
        }
      }
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
      if (!this.product || !this.product.data || !this.product.data.selected_material_id || !this.product.data.materials) {
        return null;
      }
      
      // Find the selected material in the materials array
      const selectedMaterialId = this.product.data.selected_material_id;
      return this.product.data.materials.find(material => material.id === selectedMaterialId);
    },
    async updateMaterials(materials) {
      if (!this.product || !this.product.data) return;
      
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
          
          // Calculate pieces per material (copied from MaterialsTab.calculateMaterialValues)
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
          const totalPrice = totalSquareMeters * material.price;
          
          return {
            ...material,
            piecesPerMaterial,
            totalSheets,
            totalSquareMeters,
            totalPrice,
            _needsRecalculation: undefined // Remove the flag
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
      
      // Recalculate pricing
      this.recalculatePricing();
      
      // If we have a productId, update on the server
      if (this.productId) {
        try {
          this.saving = true;
          
          const response = await fetch(`/api/v1/products/${this.productId}/update_materials`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              materials: materials
            })
          });
          
          if (!response.ok) {
            throw new Error('Failed to update materials');
          }
          
          // Update the local data with the updated materials
          this.product.data.materials = await response.json();
          
        } catch (error) {
          console.error('Error updating materials:', error);
        } finally {
          this.saving = false;
        }
      }
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
    recalculatePricing() {
      if (!this.product || !this.product.data || !this.product.data.pricing) {
        console.warn('Cannot recalculate pricing: missing product data or pricing object');
        return;
      }
      
      console.log('Recalculating pricing...');
      
      const pricing = this.product.data.pricing;
      console.log('Before calculation, pricing:', JSON.stringify(pricing));
      
      // Ensure waste_percentage and margin_percentage are set from user config if not already set
      if (!pricing.waste_percentage && pricing.waste_percentage !== 0) {
        pricing.waste_percentage = this.userConfig.waste_percentage;
        console.log('Set default waste_percentage:', pricing.waste_percentage);
      }
      
      if (!pricing.margin_percentage && pricing.margin_percentage !== 0) {
        pricing.margin_percentage = this.userConfig.margin_percentage;
        console.log('Set default margin_percentage:', pricing.margin_percentage);
      }
      
      // Calculate subtotal - ensure all values are numbers
      pricing.materials_cost = parseFloat(pricing.materials_cost) || 0;
      pricing.processes_cost = parseFloat(pricing.processes_cost) || 0;
      pricing.extras_cost = parseFloat(pricing.extras_cost) || 0;
      
      pricing.subtotal = pricing.materials_cost + pricing.processes_cost + pricing.extras_cost;
      console.log('Calculated subtotal:', pricing.subtotal);
      
      // Calculate waste
      pricing.waste_value = pricing.subtotal * (pricing.waste_percentage / 100);
      console.log('Calculated waste value:', pricing.waste_value, 
                  '(', pricing.waste_percentage, '% of', pricing.subtotal, ')');
      
      // Calculate subtotal with waste
      const subtotalWithWaste = pricing.subtotal + pricing.waste_value;
      console.log('Subtotal with waste:', subtotalWithWaste);
      
      // Get quantity from general_info if available, otherwise use product quantity or default to 1
      const quantity = 
        (this.product.data.general_info && this.product.data.general_info.quantity) || 
        this.product.data.quantity || 
        1;
      console.log('Product quantity:', quantity);
      
      // Calculate price per piece before margin
      pricing.price_per_piece_before_margin = subtotalWithWaste / quantity;
      console.log('Price per piece before margin:', pricing.price_per_piece_before_margin);
      
      // Calculate margin
      pricing.margin_value = subtotalWithWaste * (pricing.margin_percentage / 100);
      console.log('Calculated margin value:', pricing.margin_value, 
                  '(', pricing.margin_percentage, '% of', subtotalWithWaste, ')');
      
      // Calculate total price
      pricing.total_price = subtotalWithWaste + pricing.margin_value;
      console.log('Total price:', pricing.total_price);
      
      // Calculate final price per piece
      pricing.final_price_per_piece = pricing.total_price / quantity;
      console.log('Final price per piece:', pricing.final_price_per_piece);
      
      console.log('After calculation, pricing:', JSON.stringify(pricing));
    },
    // Update materials, processes, and extras costs in pricing
    ensurePricingUpdated() {
      if (!this.product || !this.product.data || !this.product.data.pricing) return;
      
      // Get total costs from materials, processes, and extras
      const materialsCost = this.product.data.materials ? this.product.data.materials.reduce((sum, material) => {
        return sum + (parseFloat(material.totalPrice) || 0);
      }, 0) : 0;
      
      const processesCost = this.product.data.processes ? this.product.data.processes.reduce((sum, process) => {
        return sum + (parseFloat(process.price) || 0);
      }, 0) : 0;
      
      const extrasCost = this.product.data.extras ? this.product.data.extras.reduce((sum, extra) => {
        const price = parseFloat(extra.unit_price) || 0;
        const quantity = parseInt(extra.quantity) || 0;
        return sum + (price * quantity);
      }, 0) : 0;
      
      // Update pricing with the calculated values
      const pricing = this.product.data.pricing;
      
      // Check if any costs have changed
      const materialsChanged = Math.abs(pricing.materials_cost - materialsCost) > 0.01;
      const processesChanged = Math.abs(pricing.processes_cost - processesCost) > 0.01;
      const extrasChanged = Math.abs(pricing.extras_cost - extrasCost) > 0.01;
      
      if (materialsChanged || processesChanged || extrasChanged) {
        pricing.materials_cost = materialsCost;
        pricing.processes_cost = processesCost;
        pricing.extras_cost = extrasCost;
        
        // Recalculate all pricing values
        this.recalculatePricing();
      }
    },
    async savePricingProduct() {
      // Create or update the product
      if (!this.productId) {
        // For new products, create with all data
        const productData = {
          description: this.product.description,
          data: this.product.data
        };
        
        // Save product data directly without recalculation
        this.saving = true;
        
        try {
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
          
          // Redirect to the products index page instead of edit
          window.location.href = '/products';
        } catch (error) {
          console.error('Error creating product:', error);
          this.error = error.message;
        } finally {
          this.saving = false;
        }
      } else {
        // For existing products, update the pricing data
        try {
          this.saving = true;
          
          const response = await fetch(`/api/v1/products/${this.productId}/update_pricing`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              pricing: this.product.data.pricing
            })
          });
          
          if (!response.ok) {
            throw new Error(`Failed to update pricing: ${response.status} ${response.statusText}`);
          }
          
          const updatedProduct = await response.json();
          this.product = updatedProduct;
          
          // Remove the automatic redirect from here
          // window.location.href = '/products';
        } catch (error) {
          console.error('Error updating pricing:', error);
        } finally {
          this.saving = false;
        }
      }
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
      
      // Recalculate pricing
      this.recalculatePricing();
      
      // If we have a productId, update on the server
      if (this.productId) {
        try {
          this.saving = true;
          
          const response = await fetch(`/api/v1/products/${this.productId}/update_processes`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              processes: processes
            })
          });
          
          if (!response.ok) {
            throw new Error('Failed to update processes');
          }
          
          // Update the local data with the updated processes
          this.product.data.processes = await response.json();
          
        } catch (error) {
          console.error('Error updating processes:', error);
        } finally {
          this.saving = false;
        }
      }
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
      if (!this.product || !this.product.data) return;
      
      // Save the selected material ID in the product data
      this.product.data.selected_material_id = materialId;
      
      // If we have a productId, update on the server
      if (this.productId) {
        try {
          fetch(`/api/v1/products/${this.productId}/update_selected_material`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-CSRF-Token': this.apiToken,
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
              selected_material_id: materialId
            })
          }).catch(error => {
            console.error('Error updating selected material:', error);
          });
        } catch (error) {
          console.error('Error updating selected material:', error);
        }
      }
    },
    
    handleMaterialCalculationChanged(materialId) {
      if (!this.product || !this.product.data) return;
      
      // Check if this is the selected material for processes
      if (materialId === this.product.data.selected_material_id && this.product.data.processes && this.product.data.processes.length > 0) {
        // Force recalculation of all processes by marking them with the recalculation flag
        const processesNeedingRecalculation = this.product.data.processes.map(process => {
          return {
            ...process,
            _needsRecalculation: true
          };
        });
        
        // This will trigger the recalculation in updateProcesses
        this.updateProcesses(processesNeedingRecalculation);
      }
    },
    
    handlePricingUpdate(updatedPricing) {
      if (!this.product || !this.product.data) return;
      
      console.log('ProductForm received pricing update:', updatedPricing);
      
      // Update the pricing data with the new values
      this.product.data.pricing = {
        ...this.product.data.pricing,
        ...updatedPricing
      };
      
      // Recalculate pricing to update all derived values
      console.log('Recalculating pricing after update');
      this.recalculatePricing();
      
      // Force update to ensure changes propagate
      this.$nextTick(() => {
        this.$forceUpdate();
      });
    },
    handleCancel() {
      window.location.href = '/products';
    }
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
      this.error = 'Failed to initialize the form. Please try refreshing the page.';
    } finally {
      // Ensure loading is set to false when all initialization is complete
      this.loading = false;
    }
  }
};
</script>

<style scoped>
.product-form {
  position: relative;
  display: flex;
  flex-direction: column;
}

.product-form-container {
  display: flex;
  flex-direction: column;
}

.nav-tabs {
  flex-shrink: 0;
  margin-bottom: 1rem !important;
}

.tab-content {
  display: flex;
  flex-direction: column;
}

.tab-pane {
  display: flex;
  flex-direction: column;
}

.tab-pane > div {
  margin-bottom: 0;
}

/* Remove any bottom margin from the last card in each tab */
.tab-pane .card:last-child,
.tab-pane > div:last-child {
  margin-bottom: 0 !important;
}

/* Remove bottom margin from the last form group in cards */
.card-body > :last-child {
  margin-bottom: 0 !important;
}

/* Remove the red border that was used for debugging */
.tab-pane {
  border: none !important;
}
</style>