<template>
  <div class="product-form">
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
    
    <div v-else>
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
            @update:product-materials="updateMaterials"
            @update:comments="updateMaterialsComments"
            @update:materials-cost="updateMaterialsCost"
          />
        </div>
        
        <!-- Processes Tab -->
        <div v-if="activeTab === 'processes' && product" class="tab-pane active">
          <processes-tab 
            :product-processes="product && product.data && product.data.processes ? product.data.processes : []"
            :available-processes="availableProcesses"
            :comments="product && product.data && product.data.processes_comments ? product.data.processes_comments : ''"
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
            @update:product-extras="updateExtras"
            @update:comments="updateExtrasComments"
          />
        </div>
        
        <!-- Pricing Tab -->
        <div v-if="activeTab === 'pricing' && product" class="tab-pane active">
          <pricing-tab 
            :pricing="product.data.pricing || defaultPricing"
            :is-new="isNew"
            @save:product="savePricingProduct"
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
      // Allow switching between general, extras, processes and pricing tabs even for new products
      // Only restrict other tabs if product doesn't exist (has no ID)
      if (['general', 'extras', 'processes', 'materials', 'pricing'].includes(tab)) {
        // These tabs are always accessible
        this.activeTab = tab;
        
        // If switching to pricing tab, ensure pricing is calculated
        if (tab === 'pricing') {
          this.recalculatePricing();
        }
      } else if (!this.productId) {
        console.warn(`Cannot switch to ${tab} tab: no product ID`);
        return;
      } else {
        // Other tabs require a product ID
        this.activeTab = tab;
      }
      
      console.log(`Set active tab to: ${tab}`);
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
    initializeNewProduct() {
      try {
        // Initialize with empty structure for a new product
        this.product = {
          description: 'Descripción del producto',
          data: {
            name: '',
            description: '',
            sku: '',
            quantity: 1,
            extras: [],
            extras_comments: '',
            processes: [],
            processes_comments: '',
            materials: [],
            materials_comments: '',
            pricing: { ...this.defaultPricing }
          }
        };
      } catch (error) {
        console.error('Error initializing new product:', error);
        this.error = 'Failed to initialize product form: ' + error.message;
      } finally {
        this.loading = false;
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
          throw new Error('Failed to create product');
        }
        
        const createdProduct = await response.json();
        
        // Redirect to the edit page for the new product
        window.location.href = `/products/${createdProduct.id}/edit`;
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
        
        const response = await fetch(`/api/v1/products/${this.productId}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': this.apiToken,
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: JSON.stringify({
            product: data
          })
        });
        
        if (!response.ok) {
          throw new Error('Failed to update product');
        }
        
        const updatedProduct = await response.json();
        this.product = updatedProduct;
        
      } catch (error) {
        console.error('Error updating product:', error);
      } finally {
        this.saving = false;
      }
    },
    async updateExtras(extras) {
      if (!this.product || !this.product.data) return;
      
      // Update local extras data
      this.product.data.extras = extras;
      
      // Calculate the total cost of extras
      const extrasCost = extras.reduce((sum, extra) => sum + (extra.unit_price * extra.quantity), 0);
      
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
    addDemoData() {
      // Only add demo data for new products
      if (this.productId) return;
      
      // Set basic product info
      this.product.data.name = 'Nuevo Producto';
      this.product.data.description = 'Descripción del producto';
      this.product.data.sku = 'NP' + Math.floor(Math.random() * 10000);
      
      // Set general info as requested
      if (!this.product.data.general_info) {
        this.product.data.general_info = {};
      }
      
      // Set specific values as requested
      this.product.data.general_info.quantity = 3000;
      this.product.data.general_info.width = 32;
      this.product.data.general_info.length = 22;
      
      // Set other general info fields with demo data
      this.product.data.general_info.inner_measurements = '30cm x 20cm';
      this.product.data.general_info.customer_name = 'Cliente Demo';
      this.product.data.general_info.customer_organization = 'Organización Demo';
      this.product.data.general_info.customer_email = 'cliente@demo.com';
      this.product.data.general_info.customer_phone = '555-123-4567';
      this.product.data.general_info.comments = 'Este es un producto de demostración para pruebas.';
      
      // Important: Also set the description in the main product object for the GeneralTab
      this.product.description = 'Descripción del producto';
      
      // Add demo pricing data - set extras cost to 0 and let recalculatePricing handle the rest
      const pricing = this.product.data.pricing;
      pricing.extras_cost = 0;
      pricing.waste_percentage = 5;
      pricing.margin_percentage = 30;
      
      // Update quantity in product data to match general info
      this.product.data.quantity = this.product.data.general_info.quantity;
      
      // Recalculate all pricing values
      this.recalculatePricing();
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
      if (!this.product || !this.product.data || !this.product.data.pricing) return;
      
      const pricing = this.product.data.pricing;
      
      // Set materials cost to 0 as requested
      pricing.materials_cost = 0;
      
      // Calculate subtotal
      pricing.subtotal = pricing.materials_cost + pricing.processes_cost + pricing.extras_cost;
      
      // Calculate waste
      pricing.waste_value = pricing.subtotal * (pricing.waste_percentage / 100);
      
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
    async savePricingProduct() {
      if (this.isNew) {
        // For new products, create the product using all data
        const productData = {
          description: this.product.data.name || 'Nuevo Producto',
          data: this.product.data
        };
        
        this.createProduct(productData);
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
            throw new Error('Failed to update pricing');
          }
          
          const updatedProduct = await response.json();
          this.product = updatedProduct;
          
        } catch (error) {
          console.error('Error updating pricing:', error);
        } finally {
          this.saving = false;
        }
      }
    },
    async updateProcesses(processes) {
      if (!this.product || !this.product.data) return;
      
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
    async fetchAvailableProcesses() {
      try {
        console.log('Fetching manufacturing processes...');
        const response = await fetch('/api/v1/manufacturing_processes', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to load manufacturing processes: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('Successfully fetched manufacturing processes:', data);
        this.availableProcesses = data;
        
      } catch (error) {
        console.error('Error loading available processes:', error);
        // Only use mock data in case of actual errors
        this.availableProcesses = [
          {
            id: -1, // Using negative IDs to indicate mock data
            description: 'Corte láser (mock)',
            width: 0,
            length: 0,
            unit: 'minuto',
            price: 150
          },
          {
            id: -2,
            description: 'Doblado (mock)',
            width: 0,
            length: 0,
            unit: 'pieza',
            price: 75
          }
        ];
      }
    },
    updateProcessesCost(cost) {
      if (!this.product || !this.product.data || !this.product.data.pricing) return;
      
      // Update processes cost in pricing
      this.product.data.pricing.processes_cost = cost;
      
      // Recalculate pricing
      this.recalculatePricing();
    },
    async updateMaterials(materials) {
      if (!this.product || !this.product.data) return;
      
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
          
          // Fetch the updated product with new pricing
          this.fetchProduct();
          
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
    
    updateMaterialsCost(cost) {
      if (!this.product || !this.product.data || !this.product.data.pricing) return;
      
      // Update materials cost in pricing
      this.product.data.pricing.materials_cost = cost;
      
      // Recalculate pricing
      this.recalculatePricing();
    },
    async fetchAvailableMaterials() {
      try {
        console.log('Fetching materials...');
        const response = await fetch('/api/v1/materials', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error(`Failed to load materials: ${response.status} ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('Successfully fetched materials:', data);
        this.availableMaterials = data;
        
      } catch (error) {
        console.error('Error loading available materials:', error);
        // Only use mock data in case of actual errors
        this.availableMaterials = [
          {
            id: -1, // Using negative IDs to indicate mock data
            description: 'Cartulina Bristol (mock)',
            ancho: 70,
            largo: 100,
            price: 15.5
          },
          {
            id: -2,
            description: 'Papel Couché (mock)',
            ancho: 90,
            largo: 130,
            price: 25.75
          }
        ];
      }
    }
  },
  created() {
    // If productId is provided, fetch the product, otherwise create a new product object
    if (this.productId) {
      this.fetchProduct();
    } else {
      this.product = {
        description: 'Descripción del producto',
        data: {
          name: '',
          description: '',
          sku: '',
          quantity: 1,
          extras: [],
          extras_comments: '',
          processes: [],
          processes_comments: '',
          materials: [],
          materials_comments: '',
          pricing: { ...this.defaultPricing }
        }
      };
      // Add demo data
      this.addDemoData();
      // Set loading to false for new products
      this.loading = false;
    }
    this.fetchAvailableExtras();
    this.fetchAvailableProcesses();
    this.fetchAvailableMaterials();
  }
};
</script>

<style scoped>
.product-form {
  position: relative;
}
</style> 