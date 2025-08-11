<template>
  <div class="product-form card">
    <div class="card-header">
      <h2>{{ editMode ? 'Edit Product' : 'New Product' }}</h2>
    </div>
    <div class="card-body">
      <form @submit.prevent="saveProduct">
        <div class="mb-3">
          <label for="product" class="form-label">Product Name</label>
          <input type="text" class="form-control" id="product" v-model="form.product" required>
        </div>
        
        <div class="mb-3">
          <label for="customer_name" class="form-label">Customer Name</label>
          <input type="text" class="form-control" id="customer_name" v-model="form.customer_name" required>
        </div>
        
        <div class="mb-3">
          <label for="customer_organization" class="form-label">Customer Organization</label>
          <input type="text" class="form-control" id="customer_organization" v-model="form.customer_organization" required>
        </div>
        
        <div class="row">
          <div class="col-md-4 mb-3">
            <label for="product_quantity" class="form-label">Quantity</label>
            <input type="number" class="form-control" id="product_quantity" v-model.number="form.product_quantity" min="1" required>
          </div>
          
          <div class="col-md-4 mb-3">
            <label for="product_width" class="form-label">Width</label>
            <input type="number" class="form-control" id="product_width" v-model.number="form.product_width" step="0.01" min="0" required>
          </div>
          
          <div class="col-md-4 mb-3">
            <label for="product_length" class="form-label">Length</label>
            <input type="number" class="form-control" id="product_length" v-model.number="form.product_length" step="0.01" min="0" required>
          </div>
        </div>
        
        <h3 class="mt-4">Materials</h3>
        <div class="materials-container mb-4">
          <div v-for="(material, index) in form.product_materials" :key="index" class="card material-card mb-3">
            <div class="card-body">
              <div class="row">
                <div class="col-md-5 mb-3">
                  <label :for="'material_id_' + index" class="form-label">Material</label>
                  <select class="form-select" :id="'material_id_' + index" v-model="material.material_id" required @change="updateMaterialPrice(index)">
                    <option value="">Select a material</option>
                    <option v-for="option in availableMaterials" :key="option.id" :value="option.id">{{ option.description }}</option>
                  </select>
                </div>
                
                <div class="col-md-3 mb-3">
                  <label :for="'quantity_' + index" class="form-label">Quantity</label>
                  <input type="number" class="form-control" :id="'quantity_' + index" v-model.number="material.quantity" min="1" @input="calculateTotals">
                </div>
                
                <div class="col-md-3 mb-3">
                  <label :for="'price_' + index" class="form-label">Price</label>
                  <input type="number" class="form-control" :id="'price_' + index" :value="getUnitPrice(material)" step="0.01" min="0" readonly>
                </div>
                
                <div class="col-md-1 mb-3 d-flex align-items-end">
                  <button type="button" class="btn btn-danger" @click="removeMaterial(index)">
                    <i class="fa fa-trash"></i>
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <button type="button" class="btn btn-secondary" @click="addMaterial">Add Material</button>
        </div>
        
        <div class="row">
          <div class="col-md-6 mb-3">
            <label for="waste_percentage" class="form-label">Waste Percentage (%)</label>
            <input type="number" class="form-control" id="waste_percentage" v-model.number="form.waste_percentage" min="0" step="0.1" @input="calculateTotals">
          </div>
          
          <div class="col-md-6 mb-3">
            <label for="margin_percentage" class="form-label">Margin Percentage (%)</label>
            <input type="number" class="form-control" id="margin_percentage" v-model.number="form.margin_percentage" min="0" step="0.1" @input="calculateTotals">
          </div>
        </div>
        
        <div class="pricing-summary card bg-dark mb-4">
          <div class="card-body">
            <h4 class="card-title">Pricing Summary</h4>
            <div class="row">
              <div class="col-md-6">
                <p><strong>Subtotal:</strong> ${{ formatCurrency(form.subtotal) }}</p>
                <p><strong>Waste Amount:</strong> ${{ formatCurrency(form.waste_price) }}</p>
                <p><strong>Margin Amount:</strong> ${{ formatCurrency(form.margin_price) }}</p>
              </div>
              <div class="col-md-6">
                <p><strong>Price per piece (with waste):</strong> ${{ formatCurrency(form.price_per_piece_with_waste) }}</p>
                <p><strong>Price per piece (with margin):</strong> ${{ formatCurrency(form.price_per_piece_with_margin) }}</p>
                <p><strong>Total Price:</strong> ${{ formatCurrency(totalPrice) }}</p>
              </div>
            </div>
          </div>
        </div>
        
        <div class="d-flex justify-content-between">
          <button type="button" class="btn btn-secondary" @click="$emit('cancel')">Cancel</button>
          <button type="submit" class="btn btn-primary">{{ editMode ? 'Update' : 'Create' }} Product</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProductForm',
  
  props: {
    editMode: {
      type: Boolean,
      default: false
    },
    product: {
      type: Object,
      default: () => ({})
    },
    materials: {
      type: Array,
      default: () => []
    }
  },
  
  data() {
    return {
      form: {
        product: '',
        customer_name: '',
        customer_organization: '',
        product_quantity: 1,
        product_width: 0,
        product_length: 0,
        waste_percentage: 10,
        margin_percentage: 30,
        subtotal: 0,
        waste_price: 0,
        price_per_piece_with_waste: 0,
        margin_price: 0,
        price_per_piece_with_margin: 0,
        product_materials: []
      },
      availableMaterials: []
    }
  },
  
  computed: {
    totalPrice() {
      return (this.form.subtotal + this.form.waste_price + this.form.margin_price) || 0;
    }
  },
  
  watch: {
    product: {
      handler(newProduct) {
        if (this.editMode && newProduct && Object.keys(newProduct).length) {
          this.form = { ...newProduct };
        }
      },
      immediate: true
    },
    materials: {
      handler(newMaterials) {
        if (newMaterials && newMaterials.length) {
          this.availableMaterials = newMaterials;
        }
      },
      immediate: true
    }
  },
  
  created() {
    // Initialize with one empty material if creating a new product
    if (!this.editMode && (!this.form.product_materials || !this.form.product_materials.length)) {
      this.addMaterial();
    }
  },
  
  methods: {
    addMaterial() {
      this.form.product_materials.push({
        material_id: '',
        quantity: 1,
        price: 0,
        total_price: 0
      });
    },
    
    removeMaterial(index) {
      this.form.product_materials.splice(index, 1);
      this.calculateTotals();
    },
    
    updateMaterialPrice(index) {
      const materialId = this.form.product_materials[index].material_id;
      const material = this.availableMaterials.find(m => m.id === materialId);
      
      if (material) {
        this.form.product_materials[index].price = this.getUnitPrice(material);
        this.calculateTotals();
      }
    },
    
    calculateTotals() {
      // Calculate materials total
      let subtotal = 0;
      this.form.product_materials.forEach(material => {
        const unitPrice = this.getUnitPrice(material);
        material.total_price = material.quantity * unitPrice;
        subtotal += material.total_price;
      });
      
      this.form.subtotal = subtotal;
      
      // Calculate waste
      const wasteAmount = subtotal * (this.form.waste_percentage / 100);
      this.form.waste_price = wasteAmount;
      
      // Calculate price per piece with waste
      const subtotalWithWaste = subtotal + wasteAmount;
      this.form.price_per_piece_with_waste = this.form.product_quantity > 0 
        ? subtotalWithWaste / this.form.product_quantity 
        : 0;
      
      // Calculate margin
      const marginAmount = subtotalWithWaste * (this.form.margin_percentage / 100);
      this.form.margin_price = marginAmount;
      
      // Calculate price per piece with margin
      const totalWithMargin = subtotalWithWaste + marginAmount;
      this.form.price_per_piece_with_margin = this.form.product_quantity > 0 
        ? totalWithMargin / this.form.product_quantity 
        : 0;
    },
    
    formatCurrency(value) {
      return (value || 0).toFixed(2);
    },
    getUnitPrice(material) {
      const price = material && material.cost;
      return parseFloat(price) || 0;
    },
    
    saveProduct() {
      this.$emit('save', { ...this.form });
    }
  }
}
</script>

<style scoped>
.material-card {
  border-left: 4px solid var(--cotalo-green);
}

.pricing-summary {
  background-color: var(--card-bg) !important;
  border: 1px solid var(--cotalo-green);
}
</style> 