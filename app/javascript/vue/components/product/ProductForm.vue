<template>
  <div class="product-form">
    <div v-if="loading" class="text-center my-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Loading...</span>
      </div>
      <p class="mt-2">Loading product data...</p>
    </div>
    
    <div v-else>
      <ul class="nav nav-tabs mb-4" id="product-tabs">
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'general' }" 
             href="#" @click.prevent="setActiveTab('general')">
            <i class="fa fa-info-circle me-1"></i> General Info
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" :class="{ active: activeTab === 'extras', disabled: !productId && activeTab !== 'extras' }" 
             href="#" @click.prevent="setActiveTab('extras')">
            <i class="fa fa-plus-circle me-1"></i> Extras
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
          <a class="nav-link" :class="{ active: activeTab === 'pricing', disabled: !productId }" 
             href="#" @click.prevent="setActiveTab('pricing')">
            <i class="fa fa-calculator me-1"></i> Precio
          </a>
        </li>
      </ul>
      
      <div class="tab-content">
        <!-- General Tab -->
        <div v-if="activeTab === 'general'" class="tab-pane active">
          <general-tab 
            :product="product" 
            :is-new="isNew"
            @update:product="updateProduct"
            @create:product="createProduct"
          />
        </div>
        
        <!-- Materials Tab -->
        <div v-if="activeTab === 'materials'" class="tab-pane active">
          <p class="text-muted">Materials tab coming soon</p>
        </div>
        
        <!-- Processes Tab -->
        <div v-if="activeTab === 'processes'" class="tab-pane active">
          <p class="text-muted">Processes tab coming soon</p>
        </div>
        
        <!-- Extras Tab -->
        <div v-if="activeTab === 'extras'" class="tab-pane active">
          <extras-tab 
            :product-extras="product.data.extras"
            :available-extras="availableExtras"
            @update:product-extras="updateExtras"
          />
        </div>
        
        <!-- Pricing Tab -->
        <div v-if="activeTab === 'pricing'" class="tab-pane active">
          <pricing-tab 
            :pricing="product.data.pricing"
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
      availableExtras: []
    };
  },
  computed: {
    apiToken() {
      return document.querySelector('meta[name="csrf-token"]')?.content;
    }
  },
  methods: {
    setActiveTab(tab) {
      // Allow switching between general and extras tabs even for new products
      if (tab !== 'general' && tab !== 'extras' && !this.productId) {
        console.warn('Cannot switch tab: no product ID');
        return;
      }
      
      console.log(`Setting active tab to: ${tab}`);
      this.activeTab = tab;
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
            pricing: {}
          };
        }
        
        console.log('Product loaded:', this.product);
      } catch (error) {
        console.error('Error loading product:', error);
        this.error = error.message;
      } finally {
        this.loading = false;
      }
    },
    initializeNewProduct() {
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
      this.loading = false;
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
        console.log('Product created successfully:', createdProduct);
        
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
        
        console.log('Product updated successfully');
      } catch (error) {
        console.error('Error updating product:', error);
      } finally {
        this.saving = false;
      }
    },
    async updateExtras(extras) {
      if (!this.productId) {
        // For new products, just update the local data
        this.product.data.extras = extras;
        console.log('Extras updated locally for new product:', extras);
        return;
      }

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
        
        console.log('Extras updated successfully');
      } catch (error) {
        console.error('Error updating extras:', error);
      } finally {
        this.saving = false;
      }
    },
    async fetchAvailableExtras() {
      try {
        const response = await fetch('/api/v1/extras', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        if (!response.ok) {
          throw new Error('Failed to load available extras');
        }
        
        this.availableExtras = await response.json();
        console.log('Available extras loaded:', this.availableExtras);
      } catch (error) {
        console.error('Error loading available extras:', error);
      }
    }
  },
  created() {
    console.log('ProductForm created with ID:', this.productId);
    this.fetchProduct();
    this.fetchAvailableExtras();
  }
};
</script>

<style scoped>
.product-form {
  position: relative;
}
</style> 