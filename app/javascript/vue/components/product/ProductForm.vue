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
          <a class="nav-link" :class="{ active: activeTab === 'materials', disabled: !productId }" 
             href="#" @click.prevent="setActiveTab('materials')">
            <i class="fa fa-cubes me-1"></i> Materiales
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'processes', disabled: !productId }" 
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
          <p class="text-muted">Materials tab coming soon</p>
        </div>
        
        <!-- Processes Tab -->
        <div v-if="activeTab === 'processes' && product" class="tab-pane active">
          <p class="text-muted">Processes tab coming soon</p>
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

export default {
  name: 'ProductForm',
  components: {
    ExtrasTab,
    GeneralTab,
    PricingTab
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
      // Allow switching between general, extras and pricing tabs even for new products
      // Only restrict other tabs if product doesn't exist (has no ID)
      if (['general', 'extras', 'pricing'].includes(tab)) {
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
          description: '',
          data: {
            general_info: {
              width: null,
              length: null,
              inner_measurements: '',
              quantity: 1,
              customer_name: '',
              customer_organization: '',
              customer_email: '',
              customer_phone: '',
              comments: ''
            },
            materials: [],
            processes: [],
            extras: [],
            extras_comments: '',
            pricing: {
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
      
      this.product.data.name = 'Nuevo Producto';
      this.product.data.description = 'Descripción del nuevo producto';
      this.product.data.sku = 'NP' + Math.floor(Math.random() * 10000);
      
      // Add demo pricing data - set only extras cost and let recalculatePricing handle the rest
      const pricing = this.product.data.pricing;
      pricing.extras_cost = 150;
      pricing.waste_percentage = 5;
      pricing.margin_percentage = 30;
      
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
      
      // Set materials and processes costs to 0 as requested
      pricing.materials_cost = 0;
      pricing.processes_cost = 0;
      
      // Calculate subtotal
      pricing.subtotal = pricing.materials_cost + pricing.processes_cost + pricing.extras_cost;
      
      // Calculate waste
      pricing.waste_value = pricing.subtotal * (pricing.waste_percentage / 100);
      
      // Calculate subtotal with waste
      const subtotalWithWaste = pricing.subtotal + pricing.waste_value;
      
      // Calculate price per piece before margin
      const quantity = this.product.data.quantity || 1;
      pricing.price_per_piece_before_margin = subtotalWithWaste / quantity;
      
      // Calculate margin
      pricing.margin_value = subtotalWithWaste * (pricing.margin_percentage / 100);
      
      // Calculate total price
      pricing.total_price = subtotalWithWaste + pricing.margin_value;
      
      // Calculate final price per piece
      pricing.final_price_per_piece = pricing.total_price / quantity;
    }
  },
  created() {
    // If productId is provided, fetch the product, otherwise create a new product object
    if (this.productId) {
      this.fetchProduct();
    } else {
      this.product = {
        data: {
          name: '',
          description: '',
          sku: '',
          quantity: 1,
          extras: [],
          extras_comments: '',
          pricing: { ...this.defaultPricing }
        }
      };
      // Add demo data
      this.addDemoData();
      // Set loading to false for new products
      this.loading = false;
    }
    this.fetchAvailableExtras();
  }
};
</script>

<style scoped>
.product-form {
  position: relative;
}
</style> 