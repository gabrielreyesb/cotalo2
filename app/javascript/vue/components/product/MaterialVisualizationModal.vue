<template>
  <div class="modal-overlay">
    <div class="modal-wrapper">
      <div class="modal-container">
        <div class="modal-header">
          <h5>Visualización de {{ material.description }}</h5>
          <button class="btn btn-sm btn-outline-light" @click="$emit('close')">
            <i class="fa fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="visualization-container" :style="containerStyle">
            <div class="material-sheet" :style="materialStyle">
              <!-- Material dimensions -->
              <div class="dimension-label width-label" :style="getWidthLabelStyle()">
                {{ material.ancho }}cm
              </div>
              <div class="dimension-label length-label" :style="getLengthLabelStyle()">
                {{ material.largo }}cm
              </div>
              <!-- Margin area visualization -->
              <div class="margin-area" :style="getMarginStyle()"></div>
              <!-- Product pieces -->
              <template v-for="(piece, index) in pieces" :key="index">
                <div class="piece-container" :style="getPieceStyle(piece)">
                  <span class="piece-label">{{ productWidth }} x {{ productLength }}</span>
                </div>
              </template>
            </div>
          </div>
          <div class="visualization-info mt-4">
            <div class="row">
              <div class="col-md-6">
                <h6 class="text-light">Material:</h6>
                <ul class="list-unstyled text-light">
                  <li><strong>Dimensiones:</strong> {{ material.ancho }}cm x {{ material.largo }}cm</li>
                  <li><strong>Área útil:</strong> {{ material.ancho - (widthMargin * 2) }}cm x {{ material.largo - (lengthMargin * 2) }}cm</li>
                  <li><strong>Piezas por material:</strong> {{ pieces.length }}</li>
                </ul>
              </div>
              <div class="col-md-6">
                <h6 class="text-light">Producto:</h6>
                <ul class="list-unstyled text-light">
                  <li><strong>Dimensiones:</strong> {{ productWidth }}cm x {{ productLength }}cm</li>
                  <li><strong>Márgenes:</strong> {{ widthMargin }}cm (ancho) x {{ lengthMargin }}cm (largo)</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="$emit('close')">Cerrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MaterialVisualizationModal',
  props: {
    material: {
      type: Object,
      required: true
    },
    productWidth: {
      type: Number,
      required: true
    },
    productLength: {
      type: Number,
      required: true
    },
    widthMargin: {
      type: Number,
      required: true
    },
    lengthMargin: {
      type: Number,
      required: true
    }
  },
  computed: {
    containerStyle() {
      return {
        width: '100%',
        height: '400px',
        overflow: 'auto',
        position: 'relative',
        backgroundColor: '#2d3238',
        border: '1px solid #198754',
        borderRadius: '4px',
        padding: '20px'
      }
    },
    materialStyle() {
      const scale = this.calculateScale();
      return {
        width: `${this.material.ancho * scale}px`,
        height: `${this.material.largo * scale}px`,
        position: 'relative',
        backgroundColor: '#3a3f44',
        border: '2px solid #198754',
        margin: '0 auto',
        boxShadow: '0 0 15px rgba(25, 135, 84, 0.15)'
      }
    },
    pieces() {
      // Calculate usable area after applying margins
      const usableWidth = this.material.ancho - (this.widthMargin * 2);
      const usableLength = this.material.largo - (this.lengthMargin * 2);
      
      // Calculate pieces that fit in both orientations within usable area
      const horizontalPieces = Math.floor(usableWidth / this.productWidth);
      const verticalPieces = Math.floor(usableLength / this.productLength);
      const normalTotal = horizontalPieces * verticalPieces;
      
      const horizontalPiecesAlt = Math.floor(usableWidth / this.productLength);
      const verticalPiecesAlt = Math.floor(usableLength / this.productWidth);
      const rotatedTotal = horizontalPiecesAlt * verticalPiecesAlt;
      
      // Use the orientation that fits more pieces
      const useRotated = rotatedTotal > normalTotal;
      
      const pieces = [];
      if (useRotated) {
        // Start position after margin
        const startX = this.widthMargin;
        const startY = this.lengthMargin;
        
        for (let row = 0; row < verticalPiecesAlt; row++) {
          for (let col = 0; col < horizontalPiecesAlt; col++) {
            pieces.push({
              x: startX + (col * this.productLength),
              y: startY + (row * this.productWidth),
              rotated: true,
              width: this.productLength,
              height: this.productWidth
            });
          }
        }
      } else {
        // Start position after margin
        const startX = this.widthMargin;
        const startY = this.lengthMargin;
        
        for (let row = 0; row < verticalPieces; row++) {
          for (let col = 0; col < horizontalPieces; col++) {
            pieces.push({
              x: startX + (col * this.productWidth),
              y: startY + (row * this.productLength),
              rotated: false,
              width: this.productWidth,
              height: this.productLength
            });
          }
        }
      }
      
      return pieces;
    }
  },
  methods: {
    calculateScale() {
      const containerWidth = 800;
      const containerHeight = 380;
      
      const materialAspectRatio = this.material.ancho / this.material.largo;
      const containerAspectRatio = containerWidth / containerHeight;
      
      let scale;
      if (materialAspectRatio > containerAspectRatio) {
        scale = containerWidth / this.material.ancho;
      } else {
        scale = containerHeight / this.material.largo;
      }
      
      return scale * 0.9;
    },
    getPieceStyle(piece) {
      const scale = this.calculateScale();
      
      return {
        position: 'absolute',
        left: `${piece.x * scale}px`,
        top: `${piece.y * scale}px`,
        width: `${piece.width * scale}px`,
        height: `${piece.height * scale}px`,
        backgroundColor: '#2d3238',
        border: '2px solid #198754',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '11px',
        color: '#e9ecef',
        transform: piece.rotated ? 'rotate(90deg)' : 'none',
        transformOrigin: 'center',
        boxShadow: '0 2px 4px rgba(0, 0, 0, 0.2)',
        transition: 'all 0.2s ease'
      };
    },
    getMarginStyle() {
      const scale = this.calculateScale();
      return {
        position: 'absolute',
        border: '1px dashed #198754',
        pointerEvents: 'none',
        width: `${(this.material.ancho - (this.widthMargin * 2)) * scale}px`,
        height: `${(this.material.largo - (this.lengthMargin * 2)) * scale}px`,
        left: `${this.widthMargin * scale}px`,
        top: `${this.lengthMargin * scale}px`
      };
    },
    getWidthLabelStyle() {
      const scale = this.calculateScale();
      return {
        position: 'absolute',
        width: '100%',
        textAlign: 'center',
        bottom: '-25px',
        left: '0',
        color: '#e9ecef'
      };
    },
    getLengthLabelStyle() {
      const scale = this.calculateScale();
      return {
        position: 'absolute',
        right: '-45px',
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        color: '#e9ecef',
        transform: 'rotate(90deg)',
        transformOrigin: 'center'
      };
    }
  }
}
</script>

<style scoped>
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
  max-width: 900px;
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

.visualization-container {
  background-color: #2d3238;
  border-radius: 6px;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 1.5rem;
  border: 1px solid #198754;
}

.material-sheet {
  box-shadow: 0 0 15px rgba(25, 135, 84, 0.15);
  background-color: #3a3f44;
  border: 2px solid #198754;
}

.piece-container {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  background-color: #2d3238;
  border: 2px solid #198754;
  transition: all 0.2s ease;
}

.piece-container:hover {
  background-color: rgba(25, 135, 84, 0.2);
  transform: scale(1.02);
}

.piece-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
  padding: 2px;
  color: #e9ecef;
  font-size: 11px;
}

.visualization-info {
  background-color: #2d3238;
  border-radius: 6px;
  padding: 1rem;
  margin-top: 1rem;
  border: 1px solid rgba(25, 135, 84, 0.2);
}

.visualization-info h6 {
  color: #198754;
  margin-bottom: 0.75rem;
  font-weight: 600;
}

.visualization-info ul li {
  color: #adb5bd;
  margin-bottom: 0.5rem;
}

.visualization-info ul li strong {
  color: #e9ecef;
}

.btn-secondary {
  background-color: #2d3238;
  border-color: #198754;
  color: #198754;
}

.btn-secondary:hover {
  background-color: #198754;
  border-color: #198754;
  color: white;
}

.btn-outline-light:hover {
  background-color: rgba(25, 135, 84, 0.2);
  border-color: white;
}

.margin-area {
  position: absolute;
  border: 1px dashed #198754;
  pointer-events: none;
}

.dimension-label {
  font-size: 12px;
  font-weight: 500;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
}
</style> 