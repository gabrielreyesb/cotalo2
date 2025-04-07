<template>
  <div class="modal-test">
    <div class="container py-4">
      <h2 class="mb-4">Modal Test</h2>
      
      <button class="btn btn-primary" @click="showModal = true">
        Open Modal
      </button>

      <!-- Simple Modal -->
      <div v-if="showModal" class="modal-overlay">
        <div class="modal-wrapper">
          <div class="modal-container">
            <div class="modal-header">
              <h5>Test Modal</h5>
              <button class="btn btn-sm btn-outline-light" @click="showModal = false">
                <i class="fa fa-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <p>This is a simple modal test.</p>
            </div>
            <div class="modal-footer">
              <button class="btn btn-secondary" @click="showModal = false">Close</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ModalTest',
  data() {
    return {
      showModal: false
    }
  }
}
</script>

<style scoped>
.modal-test {
  min-height: 100vh;
  background-color: #1e2124;
  color: #e9ecef;
}

.modal-overlay {
  position: fixed;
  z-index: 9999;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.75);
  display: flex;
  justify-content: center;
  align-items: center;
}

.modal-wrapper {
  width: 90%;
  max-width: 500px;
  margin: 2rem;
}

.modal-container {
  background: #1e2124;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 1rem;
  border: 1px solid #2d3238;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #2d3238;
  background: linear-gradient(to right, #198754 0%, #1e2124 100%);
  margin: -1rem -1rem 0;
  border-radius: 8px 8px 0 0;
  padding-left: 1.5rem;
}

.modal-header h5 {
  color: white;
  margin: 0;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.modal-body {
  padding: 1rem;
}

.modal-footer {
  padding: 1rem;
  border-top: 1px solid #2d3238;
  display: flex;
  justify-content: flex-end;
}
</style> 