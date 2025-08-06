import { createApp } from 'vue'
import ProductFormV2 from '../vue/components/product/ProductFormV2.vue'

document.addEventListener('DOMContentLoaded', () => {
  const appElement = document.getElementById('product-form-app')
  
  if (appElement) {
    const app = createApp(ProductFormV2, {
      productId: appElement.dataset.productId || null,
      isNew: !appElement.dataset.productId
    })
    
    app.mount('#product-form-app')
  }
}) 