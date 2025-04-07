<template>
  <div class="visualization-panel" :class="{ 'is-open': isOpen }">
    <div class="panel-content">
      <div class="panel-header">
        <h3>Visualización del Material</h3>
        <button class="btn-close" @click="$emit('close')" aria-label="Cerrar">
          <i class="fa fa-times"></i>
        </button>
      </div>

      <div class="panel-body" v-if="material">
        <div class="material-info">
          <h4>{{ material.description }}</h4>
          <div class="dimensions">
            <span>{{ material.ancho }}cm x {{ material.largo }}cm</span>
            <small class="ms-2 text-muted">(Márgenes: {{ widthMargin }}cm x {{ lengthMargin }}cm)</small>
          </div>
        </div>

        <div class="visualization-container">
          <div class="material-sheet" :style="materialStyle">
            <!-- Material dimensions -->
            <div class="dimension-label width-label">{{ material.ancho }}cm</div>
            <div class="dimension-label length-label">{{ material.largo }}cm</div>
            
            <!-- Margin areas -->
            <div class="margin-area margin-top" :style="marginTopStyle"></div>
            <div class="margin-area margin-bottom" :style="marginBottomStyle"></div>
            <div class="margin-area margin-left" :style="marginLeftStyle"></div>
            <div class="margin-area margin-right" :style="marginRightStyle"></div>
            
            <!-- Product pieces -->
            <template v-for="(piece, index) in pieces" :key="index">
              <div class="piece" :style="getPieceStyle(piece)">
                <span class="piece-label">{{ productWidth }} x {{ productLength }}</span>
              </div>
            </template>
          </div>
        </div>

        <div class="visualization-info">
          <div class="info-row">
            <span>Piezas por material:</span>
            <strong>{{ pieces.length }}</strong>
          </div>
          <div class="info-row">
            <span>Área total:</span>
            <strong>{{ totalArea }}cm²</strong>
          </div>
          <div class="info-row">
            <span>Área útil:</span>
            <strong>{{ usableArea }}cm²</strong>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MaterialVisualizationPanel',
  props: {
    isOpen: {
      type: Boolean,
      default: false
    },
    material: {
      type: Object,
      default: null
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
      default: 0
    },
    lengthMargin: {
      type: Number,
      default: 0
    }
  },
  computed: {
    pieces() {
      if (!this.material || !this.productWidth || !this.productLength) return [];
      
      const pieces = [];
      const materialWidth = this.material.ancho;
      const materialLength = this.material.largo;
      
      // Calculate usable area considering margins
      const usableWidth = materialWidth - (this.widthMargin * 2);
      const usableLength = materialLength - (this.lengthMargin * 2);
      
      // Calculate how many pieces fit in the usable area
      const piecesAcross = Math.floor(usableWidth / this.productWidth);
      const piecesDown = Math.floor(usableLength / this.productLength);
      
      // Create piece positions, offset by margins
      for (let y = 0; y < piecesDown; y++) {
        for (let x = 0; x < piecesAcross; x++) {
          pieces.push({
            x: (x * this.productWidth) + this.widthMargin,
            y: (y * this.productLength) + this.lengthMargin
          });
        }
      }
      
      return pieces;
    },
    materialStyle() {
      const scale = this.calculateScale();
      return {
        width: `${this.material.ancho * scale}px`,
        height: `${this.material.largo * scale}px`,
        position: 'relative'
      };
    },
    marginTopStyle() {
      const scale = this.calculateScale();
      return {
        height: `${this.lengthMargin * scale}px`,
        width: '100%',
        top: 0
      };
    },
    marginBottomStyle() {
      const scale = this.calculateScale();
      return {
        height: `${this.lengthMargin * scale}px`,
        width: '100%',
        bottom: 0
      };
    },
    marginLeftStyle() {
      const scale = this.calculateScale();
      return {
        width: `${this.widthMargin * scale}px`,
        height: '100%',
        left: 0
      };
    },
    marginRightStyle() {
      const scale = this.calculateScale();
      return {
        width: `${this.widthMargin * scale}px`,
        height: '100%',
        right: 0
      };
    },
    totalArea() {
      if (!this.material) return 0;
      return this.material.ancho * this.material.largo;
    },
    usableArea() {
      if (!this.material) return 0;
      const usableWidth = this.material.ancho - (this.widthMargin * 2);
      const usableLength = this.material.largo - (this.lengthMargin * 2);
      return usableWidth * usableLength;
    }
  },
  methods: {
    calculateScale() {
      if (!this.material) return 1;
      
      const maxWidth = 500; // Maximum width of visualization
      const maxHeight = 400; // Maximum height of visualization
      
      const scaleX = maxWidth / this.material.ancho;
      const scaleY = maxHeight / this.material.largo;
      
      // Use the smaller scale to ensure the entire material fits
      return Math.min(scaleX, scaleY);
    },
    getPieceStyle(piece) {
      const scale = this.calculateScale();
      return {
        position: 'absolute',
        left: `${piece.x * scale}px`,
        top: `${piece.y * scale}px`,
        width: `${this.productWidth * scale}px`,
        height: `${this.productLength * scale}px`
      };
    }
  }
}
</script>

<style scoped>
.visualization-panel {
  position: fixed;
  top: 0;
  right: -600px;
  width: 600px;
  height: 100vh;
  background: #1e2124;
  border-left: 1px solid #2d3238;
  transition: right 0.3s ease;
  z-index: 1000;
}

.visualization-panel.is-open {
  right: 0;
}

.panel-content {
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 20px;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 20px;
  border-bottom: 1px solid #2d3238;
}

.panel-header h3 {
  margin: 0;
  color: #e9ecef;
}

.btn-close {
  background: none;
  border: none;
  color: #e9ecef;
  cursor: pointer;
  padding: 5px;
}

.panel-body {
  flex: 1;
  overflow-y: auto;
  padding: 20px 0;
}

.material-info {
  margin-bottom: 20px;
}

.material-info h4 {
  margin: 0 0 10px 0;
  color: #e9ecef;
}

.dimensions {
  color: #adb5bd;
}

.visualization-container {
  background: #2d3238;
  border-radius: 8px;
  padding: 20px;
  margin: 20px 0;
  display: flex;
  justify-content: center;
  align-items: center;
}

.material-sheet {
  position: relative;
  background: #3a3f44;
  border: 2px solid #198754;
}

.piece {
  background: rgba(25, 135, 84, 0.2);
  border: 1px solid #198754;
  display: flex;
  align-items: center;
  justify-content: center;
}

.piece-label {
  font-size: 12px;
  color: #e9ecef;
  text-shadow: 0 1px 2px rgba(0,0,0,0.5);
}

.dimension-label {
  position: absolute;
  color: #e9ecef;
  font-size: 12px;
}

.width-label {
  top: -25px;
  left: 50%;
  transform: translateX(-50%);
}

.length-label {
  right: -35px;
  top: 50%;
  transform: rotate(90deg) translateX(-50%);
  transform-origin: left;
}

.visualization-info {
  background: #2d3238;
  border-radius: 8px;
  padding: 15px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  color: #e9ecef;
}

.info-row:last-child {
  margin-bottom: 0;
}

.margin-area {
  position: absolute;
  background: rgba(220, 53, 69, 0.1);
  border: 1px dashed rgba(220, 53, 69, 0.5);
  pointer-events: none;
  z-index: 1;
}
</style> 