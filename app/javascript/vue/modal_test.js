import { createApp } from 'vue'
import ModalTest from './components/product/ModalTest.vue'

document.addEventListener('DOMContentLoaded', () => {
  const modalTestEl = document.getElementById('modal-test')
  
  if (modalTestEl) {
    const app = createApp({
      components: {
        ModalTest
      },
      template: '<ModalTest />'
    })
    
    app.mount('#modal-test')
  }
}) 