<template>
  <div class="materials-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-9 mb-3 mb-md-0">
              <div class="d-flex align-items-center">
                <label for="material-select" class="form-label mb-0 me-2">{{ translations.materials.select_material }}</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  :title="translations.materials_calculation_tooltip"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
              <select 
                id="material-select" 
                v-model="materialIdForAdd" 
                class="form-select bg-dark text-white border-secondary"
                :disabled="!availableMaterials.length"
                @change="onMaterialSelect"
              >
                <option value="" disabled>{{ translations.materials.select_material }}</option>
                <option 
                  v-for="material in availableMaterials" 
                  :key="material.id" 
                  :value="material.id"
                >
                  {{ material.description }}
                </option>
              </select>
              <div v-if="validationMessage" class="text-danger mt-2">
                {{ validationMessage }}
              </div>
            </div>
            
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary w-100" 
                @click="addMaterial" 
                :disabled="!canAdd"
                :title="validationMessage"
              >
                <i class="fa fa-plus me-1"></i> {{ translations.materials.add_material }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- No Materials Message -->
    <div v-if="!productMaterials.length" class="text-center my-5">
      <p class="text-muted">{{ translations.materials.no_materials }}</p>
    </div>

    <!-- Materials Table/Cards -->
    <div class="green-accent-panel mt-4">
      <div class="card" v-if="productMaterials.length">
        <div class="card-body p-0">
          <!-- Desktop Table -->
          <div class="d-none d-md-block">
            <table class="table table-dark table-striped product-table mb-0">
              <thead>
                <tr>
                  <th style="width: 32%">{{ translations.materials.description }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.width }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.length }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.price }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.pieces_per_material }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.total_sheets }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.total_square_meters }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.total_price }}</th>
                  <th style="width: 16%" class="text-center">{{ translations.materials.actions }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(material, index) in productMaterials" :key="index">
                  <td class="text-truncate" style="max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="material.description">{{ material.description }}</td>
                  <td class="text-end">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end" 
                      v-model.number="material.ancho" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      :title="translations.materials.width"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-end">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end" 
                      v-model.number="material.largo" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      :title="translations.materials.length"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-end">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end" 
                      v-model.number="material.price" 
                      min="0"
                      step="0.01"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      :title="translations.materials.price"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-end">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end" 
                      v-model.number="material.piecesPerMaterial" 
                      min="1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      :title="translations.materials.pieces_per_material"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-end">{{ material.totalSheets }}</td>
                  <td class="text-end">{{ material.totalSquareMeters.toFixed(2) }}</td>
                  <td class="text-end">{{ formatCurrency(material.totalPrice) }}</td>
                  <td class="text-center" style="min-width: 140px;">
                    <div class="d-flex align-items-center justify-content-center gap-2">
                      <button 
                        class="btn btn-sm btn-outline-info" 
                        @click="openVisualization(material)"
                        :title="translations.materials.visualize"
                      >
                        <i class="fa fa-eye"></i>
                      </button>
                      <button 
                        class="btn btn-sm btn-outline-danger" 
                        @click="removeMaterial(index)"
                        :title="translations.materials.remove"
                      >
                        <i class="fa fa-trash"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <th colspan="7" class="text-end">{{ translations.materials.total }}:</th>
                  <th class="text-end">{{ formatCurrency(totalCost) }}</th>
                  <th></th>
                </tr>
              </tfoot>
            </table>
          </div>
          
          <!-- Mobile Cards -->
          <div class="d-md-none">
            <div v-for="(material, index) in productMaterials" :key="index" class="card mb-3 shadow-sm">
              <div class="card-body p-2">
                <!-- First row: Material description only -->
                <h6 class="card-title mb-2">{{ material.description }}</h6>
                <!-- Second row: Width, length, price -->
                <div class="row g-2 mb-2">
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.ancho" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      placeholder="Ancho"
                    />
                  </div>
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.largo" 
                      min="0"
                      step="0.1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      placeholder="Largo"
                    />
                  </div>
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-center p-2 w-100 material-badge editable-badge"
                      v-model.number="material.price" 
                      min="0"
                      step="0.01"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      placeholder="Precio"
                    />
                  </div>
                </div>
                <!-- Rest of mobile card remains the same -->
                <div class="row g-2 mb-2">
                  <div class="col-4">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end p-2 w-100 material-badge editable-badge"
                      v-model.number="material.piecesPerMaterial" 
                      min="1"
                      @change="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Puedes editar este valor manualmente para ajustar la cantidad de piezas por material"
                    />
                  </div>
                  <div class="col-4">
                    <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                      {{ material.totalSheets }} pgs
                    </div>
                  </div>
                  <div class="col-4">
                    <div class="badge bg-dark d-block text-center p-2 w-100 material-badge">
                      {{ material.totalSquareMeters.toFixed(1) }}
                    </div>
                  </div>
                </div>
                <!-- Fourth row: Total price and action buttons -->
                <div class="d-flex justify-content-between align-items-center">
                  <span class="badge bg-success fs-5">{{ formatCurrency(material.totalPrice) }}</span>
                  <div class="d-flex align-items-center">
                    <button 
                      class="btn btn-sm btn-outline-danger px-2 py-1" 
                      @click="removeMaterial(index)"
                    >
                      <i class="fa fa-trash fa-sm"></i>
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <!-- Total cost for small screens -->
            <div class="card bg-dark text-white">
              <div class="card-body py-2">
                <div class="d-flex justify-content-between align-items-center">
                  <span class="fw-bold">Total materiales:</span>
                  <span class="fs-5">{{ formatCurrency(totalCost) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Comments Section -->
    <div class="green-accent-panel mt-3 mb-4">
      <div class="card">
        <div class="card-body">
          <div class="form-group">
            <label for="material-comments" class="form-label">{{ translations.materials_tab.comments_label }}</label>
            <textarea 
              id="material-comments" 
              class="form-control" 
              v-model="globalComments" 
              rows="3"
              :placeholder="translations.materials_tab.comments_placeholder"
              @change="updateGlobalComments"
            ></textarea>
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Overlay -->
    <div v-if="visualizationMaterial" class="custom-overlay">
      <div class="custom-overlay-content">
        <button class="btn-close float-end" @click="visualizationMaterial = null" aria-label="Cerrar" style="font-size: 1.5rem; opacity: 0.8;">×</button>
        <h4>{{ translations.materials.visualization_title }}</h4>
        <div v-if="visualizationMaterial">
          <p><strong>{{ visualizationMaterial.description }}</strong> ({{ Number(visualizationMaterial.ancho).toFixed(1) }}cm x {{ Number(visualizationMaterial.largo).toFixed(1) }}cm)</p>
          <svg
            :width="550"
            :height="400"
            viewBox="0 0 600 400"
            style="background: #23272b; border-radius: 8px; display: block; margin: 0 auto;"
          >
            <!-- Material rectangle -->
            <rect :x="padding" :y="padding" :width="materialW" :height="materialH" fill="#333" stroke="#42b983" stroke-width="3" />
            <!-- Material width label -->
            <text
              :x="padding + materialW / 2"
              :y="padding - 12"
              text-anchor="middle"
              font-size="18"
              fill="#42b983"
              font-weight="bold"
            >
              {{ Number(visualizationMaterial.ancho).toFixed(1) }}cm
            </text>
            <!-- Material height label -->
            <text
              :x="padding - 18"
              :y="padding + materialH / 2"
              text-anchor="middle"
              font-size="18"
              fill="#42b983"
              font-weight="bold"
              :transform="`rotate(-90, ${padding - 18}, ${padding + materialH / 2})`"
            >
              {{ Number(visualizationMaterial.largo).toFixed(1) }}cm
            </text>
            <!-- Margin rectangle -->
            <rect
              :x="padding + marginW"
              :y="padding + marginH"
              :width="materialW - 2 * marginW"
              :height="materialH - 2 * marginH"
              fill="#23272b"
              stroke="#888"
              stroke-dasharray="4,2"
              stroke-width="2"
            />
            <!-- Product rectangles -->
            <g v-for="(rect, i) in productRects" :key="i">
              <rect
                :x="padding + marginW + rect.x"
                :y="padding + marginH + rect.y"
                :width="rect.w"
                :height="rect.h"
                fill="#42b983"
                fill-opacity="0.7"
                stroke="#fff"
                stroke-width="1"
              />
              <!-- Only label the first product rectangle -->
              <g v-if="i === 0">
                <!-- Product width label (centered inside) -->
                <text
                  :x="padding + marginW + rect.x + rect.w / 2"
                  :y="padding + marginH + rect.y + rect.h / 2 - 50"
                  text-anchor="middle"
                  font-size="16"
                  fill="#fff"
                  font-weight="bold"
                  stroke="#23272b"
                  stroke-width="0.5"
                >
                  {{ optimalOrientation.rotated ? Number(productLength).toFixed(1) : Number(productWidth).toFixed(1) }}cm
                </text>
                <!-- Product height label (centered inside, rotated) -->
                <text
                  :x="padding + marginW + rect.x + 25"
                  :y="padding + marginH + rect.y + rect.h / 2 + 15"
                  text-anchor="middle"
                  font-size="16"
                  fill="#fff"
                  font-weight="bold"
                  stroke="#23272b"
                  stroke-width="0.5"
                  :transform="`rotate(-90, ${padding + marginW + rect.x + 25}, ${padding + marginH + rect.y + rect.h / 2 + 15})`"
                >
                  {{ optimalOrientation.rotated ? Number(productWidth).toFixed(1) : Number(productLength).toFixed(1) }}cm
                </text>
              </g>
            </g>
          </svg>
          <div class="mt-2 small text-muted">
            <span>{{ translations.materials.visualization_legend }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MaterialsTab',
  emits: {
    'update:product-materials': null,
    'update:comments': null,
    'update:materials-cost': null,
    'material-calculation-changed': null
  },
  props: {
    productMaterials: {
      type: Array,
      required: true
    },
    availableMaterials: {
      type: Array,
      required: true
    },
    comments: {
      type: String,
      default: ''
    },
    productWidth: {
      type: Number,
      default: 0
    },
    productLength: {
      type: Number,
      default: 0
    },
    productQuantity: {
      type: Number,
      default: 1
    },
    widthMargin: {
      type: Number,
      default: 0
    },
    lengthMargin: {
      type: Number,
      default: 0
    },
    translations: {
      type: Object,
      required: true
    }
  },
  data() {
    console.log('Initializing MaterialsTab component');
    return {
      visualizationMaterial: null,
      materialIdForAdd: '',
      globalComments: this.comments,
      validationMessage: '',
    };
  },
  created() {
    // Remove the initial material selection since we don't need it anymore
  },
  computed: {
    canAdd() {
      if (!this.materialIdForAdd) {
        this.validationMessage = '';
        return false;
      }

      // Validate product dimensions and quantity
      if (!this.productQuantity || this.productQuantity <= 0) {
        this.validationMessage = 'Por favor, especifica la cantidad de piezas del producto en la pestaña de información general';
        return false;
      }
      if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
        this.validationMessage = 'Por favor, especifica el ancho y largo del producto en la pestaña de información general';
        return false;
      }

      return this.materialIdForAdd && this.selectedMaterialDetails;
    },
    selectedMaterialDetails() {
      if (!this.materialIdForAdd) return null;
      return this.availableMaterials.find(m => m.id === this.materialIdForAdd);
    },
    totalCost() {
      return this.productMaterials.reduce((sum, material) => sum + material.totalPrice, 0);
    },
    padding() {
      return 40;
    },
    // SVG scaling factors
    materialW() {
      const maxW = 520;
      const maxH = 320;
      const ancho = Number(this.visualizationMaterial?.ancho) || 1;
      const largo = Number(this.visualizationMaterial?.largo) || 1;
      const scale = Math.min(maxW / ancho, maxH / largo);
      return ancho * scale;
    },
    materialH() {
      const maxW = 520;
      const maxH = 320;
      const ancho = Number(this.visualizationMaterial?.ancho) || 1;
      const largo = Number(this.visualizationMaterial?.largo) || 1;
      const scale = Math.min(maxW / ancho, maxH / largo);
      return largo * scale;
    },
    marginW() {
      const maxW = 520;
      const maxH = 320;
      const ancho = Number(this.visualizationMaterial?.ancho) || 1;
      const largo = Number(this.visualizationMaterial?.largo) || 1;
      const scale = Math.min(maxW / ancho, maxH / largo);
      return (this.widthMargin || 0) * scale;
    },
    marginH() {
      const maxW = 520;
      const maxH = 320;
      const ancho = Number(this.visualizationMaterial?.ancho) || 1;
      const largo = Number(this.visualizationMaterial?.largo) || 1;
      const scale = Math.min(maxW / ancho, maxH / largo);
      return (this.lengthMargin || 0) * scale;
    },
    // Determine the optimal orientation for visualization
    optimalOrientation() {
      if (!this.visualizationMaterial) return { rotated: false };
      const materialWidth = Number(this.visualizationMaterial.ancho) || 1;
      const materialLength = Number(this.visualizationMaterial.largo) || 1;
      const productWidth = this.productWidth || 1;
      const productLength = this.productLength || 1;
      const widthMargin = this.widthMargin || 0;
      const lengthMargin = this.lengthMargin || 0;
      // Add margins to product dimensions
      const totalProductWidth = productWidth + widthMargin;
      const totalProductLength = productLength + lengthMargin;
      // Normal orientation
      const piecesAcross = Math.floor(materialWidth / totalProductWidth);
      const piecesDown = Math.floor(materialLength / totalProductLength);
      const normalCount = piecesAcross * piecesDown;
      // Rotated orientation
      const piecesAcrossRot = Math.floor(materialWidth / totalProductLength);
      const piecesDownRot = Math.floor(materialLength / totalProductWidth);
      const rotatedCount = piecesAcrossRot * piecesDownRot;
      return rotatedCount > normalCount
        ? { rotated: true, cols: piecesAcrossRot, rows: piecesDownRot, productW: totalProductLength, productH: totalProductWidth }
        : { rotated: false, cols: piecesAcross, rows: piecesDown, productW: totalProductWidth, productH: totalProductLength };
    },
    productW() {
      // Use the optimal orientation for width
      const maxW = 520;
      const maxH = 320;
      const ancho = Number(this.visualizationMaterial?.ancho) || 1;
      const largo = Number(this.visualizationMaterial?.largo) || 1;
      const scale = Math.min(maxW / ancho, maxH / largo);
      return (this.optimalOrientation.productW || 1) * scale;
    },
    productH() {
      // Use the optimal orientation for height
      const maxW = 520;
      const maxH = 320;
      const ancho = Number(this.visualizationMaterial?.ancho) || 1;
      const largo = Number(this.visualizationMaterial?.largo) || 1;
      const scale = Math.min(maxW / ancho, maxH / largo);
      return (this.optimalOrientation.productH || 1) * scale;
    },
    productRects() {
      if (!this.visualizationMaterial) return [];
      const areaW = this.materialW - 2 * this.marginW;
      const areaH = this.materialH - 2 * this.marginH;
      // Use the same logic as business calculation for cols/rows
      const orientation = this.optimalOrientation;
      const cols = orientation.cols;
      const rows = orientation.rows;
      // Calculate product size so all fit perfectly in the area
      const productW = cols > 0 ? areaW / cols : 0;
      const productH = rows > 0 ? areaH / rows : 0;
      const rects = [];
      for (let y = 0; y < rows; y++) {
        for (let x = 0; x < cols; x++) {
          rects.push({ x: x * productW, y: y * productH, w: productW, h: productH });
        }
      }
      return rects;
    },
    // Override productW and productH for visualization to use the scaled values
    visProductW() {
      const areaW = this.materialW - 2 * this.marginW;
      const cols = this.optimalOrientation.cols;
      return cols > 0 ? areaW / cols : 0;
    },
    visProductH() {
      const areaH = this.materialH - 2 * this.marginH;
      const rows = this.optimalOrientation.rows;
      return rows > 0 ? areaH / rows : 0;
    },
  },
  methods: {
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(value || 0);
    },
    onMaterialSelect() {
      if (!this.materialIdForAdd) {
        this.validationMessage = '';
        return;
      }

      // Validate product dimensions and quantity
      if (!this.productQuantity || this.productQuantity <= 0) {
        this.validationMessage = 'Por favor, especifica la cantidad de piezas del producto en la pestaña de información general';
        return;
      }
      if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
        this.validationMessage = 'Por favor, especifica el ancho y largo del producto en la pestaña de información general';
        return;
      }

      this.validationMessage = '';
    },
    addMaterial() {
      if (!this.selectedMaterialDetails) {
        this.validationMessage = 'Por favor, selecciona un material.';
        return;
      }

      const material = {
        id: this.selectedMaterialDetails.id,
        description: this.selectedMaterialDetails.description,
        client_description: this.selectedMaterialDetails.client_description,
        resistance: this.selectedMaterialDetails.resistance,
        ancho: this.selectedMaterialDetails.ancho,
        largo: this.selectedMaterialDetails.largo,
        price: this.selectedMaterialDetails.price,
        piecesPerMaterial: this.calculatePiecesPerSheet(
          this.selectedMaterialDetails.ancho,
          this.selectedMaterialDetails.largo,
          this.productWidth,
          this.productLength,
          this.widthMargin,
          this.lengthMargin
        ) || 1,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0
      };

      // Add material
      this.productMaterials.push(material);
      
      // Reset and emit
      this.materialIdForAdd = '';
      this.validationMessage = '';
      this.$emit('update:product-materials', this.productMaterials);
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });
      
      // Calculate values
      this.updateMaterialCalculations({ 
        index: this.productMaterials.length - 1, 
        updatePiecesPerMaterial: true, 
        material 
      });
    },
    updateMaterialCalculations({ index, updatePiecesPerMaterial = false, material }) {
      if (!material) return;

      const productQuantity = this.productQuantity || 1;
      const productWidth = parseFloat(this.productWidth) || 0;
      const productLength = parseFloat(this.productLength) || 0;

      // Add margins to product dimensions
      const effectiveProductWidth = productWidth + this.widthMargin;
      const effectiveProductLength = productLength + this.lengthMargin;

      let piecesPerMaterial = material.piecesPerMaterial || 1;

      // Only recalculate piecesPerMaterial if:
      // 1. This is a new material (no piecesPerMaterial set)
      // 2. The material dimensions have changed
      // 3. The product dimensions have changed
      const shouldRecalculate = updatePiecesPerMaterial && 
        effectiveProductWidth > 0 && 
        effectiveProductLength > 0 &&
        (!material._piecesPerMaterialSet || // New material
         material._lastWidth !== material.ancho || // Width changed
         material._lastLength !== material.largo || // Length changed
         material._lastProductWidth !== productWidth || // Product width changed
         material._lastProductLength !== productLength); // Product length changed

      if (shouldRecalculate) {
        const materialWidth = parseFloat(material.ancho) || 0;
        const materialLength = parseFloat(material.largo) || 0;

        if (materialWidth > 0 && materialLength > 0) {
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

        // Store the current dimensions to detect changes next time
        material._lastWidth = material.ancho;
        material._lastLength = material.largo;
        material._lastProductWidth = productWidth;
        material._lastProductLength = productLength;
        material._piecesPerMaterialSet = true;
      }

      // Calculate total sheets needed
      const totalSheets = piecesPerMaterial > 0 ? Math.ceil(productQuantity / piecesPerMaterial) : 0;

      // Calculate total square meters
      const materialWidth = parseFloat(material.ancho) || 0;
      const materialLength = parseFloat(material.largo) || 0;
      const totalSquareMeters = totalSheets * (materialWidth * materialLength) / 10000; // convert cm² to m²

      // Calculate total price
      const totalPrice = totalSquareMeters * (material.price || 0);

      // Update the material with new calculations
      const updatedMaterial = {
        ...material,
        piecesPerMaterial,
        totalSheets,
        totalSquareMeters,
        totalPrice
      };

      // Emit the calculation change event
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        totalSheets,
        totalSquareMeters,
        totalPrice,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });

      // Update the materials array
      const updatedMaterials = [...this.productMaterials];
      updatedMaterials[index] = updatedMaterial;
      this.$emit('update:product-materials', updatedMaterials);
    },
    calculatePiecesPerSheet(materialWidth, materialLength, productWidth, productLength, widthMargin, lengthMargin) {
      if (!materialWidth || !materialLength || !productWidth || !productLength) return 0;
      
      // Add margins to product dimensions
      const totalProductWidth = productWidth + widthMargin;
      const totalProductLength = productLength + lengthMargin;
      
      // Calculate how many pieces fit in each direction
      const piecesAcross = Math.floor(materialWidth / totalProductWidth);
      const piecesDown = Math.floor(materialLength / totalProductLength);
      
      // Try rotating the piece if it yields more pieces
      const piecesAcrossRotated = Math.floor(materialWidth / totalProductLength);
      const piecesDownRotated = Math.floor(materialLength / totalProductWidth);
      
      // Return the maximum number of pieces possible
      return Math.max(
        piecesAcross * piecesDown,
        piecesAcrossRotated * piecesDownRotated
      );
    },
    removeMaterial(index) {
      const removedMaterial = this.productMaterials[index];
      this.productMaterials.splice(index, 1);
      
      // Emit updates in the correct order
      this.$emit('update:product-materials', this.productMaterials);
      this.$emit('update:materials-cost', this.totalCost);
      this.$emit('material-calculation-changed', {
        materialId: removedMaterial.id,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });
    },
    updateGlobalComments() {
      this.$emit('update:comments', this.globalComments);
    },
    openVisualization(material) {
      this.visualizationMaterial = material;
    },
    initializeTooltips() {
      // Dispose existing tooltips first
      this.disposeTooltips();
      
      // Initialize new tooltips
      const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
      tooltipTriggerList.forEach(tooltipTriggerEl => {
        new bootstrap.Tooltip(tooltipTriggerEl, {
          html: true,
          placement: tooltipTriggerEl.dataset.bsPlacement || 'bottom'
        });
      });
    },
    disposeTooltips() {
      const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
      tooltips.forEach(element => {
        const tooltip = bootstrap.Tooltip.getInstance(element);
        if (tooltip) {
          tooltip.dispose();
        }
      });
    },
    handleLanguageChange() {
      // Reinitialize tooltips when language changes
      this.$nextTick(() => {
        this.initializeTooltips();
      });
    }
  },
  watch: {
    comments(newValue) {
      this.globalComments = newValue;
    },
    productMaterials: {
      handler(newVal) {
        console.log('productMaterials changed:', newVal);
      },
      immediate: true
    },
    productWidth() {
      // Recalculate all materials when product width changes
      this.productMaterials.forEach((_, index) => {
        this.updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material: this.productMaterials[index] });
      });
    },
    productLength() {
      // Recalculate all materials when product length changes
      this.productMaterials.forEach((_, index) => {
        this.updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material: this.productMaterials[index] });
      });
    }
  },
  mounted() {
    // Initialize tooltips
    this.initializeTooltips();

    // Listen for language changes
    window.addEventListener('languageChanged', this.handleLanguageChange);
  },
  beforeUnmount() {
    // Clean up event listener
    window.removeEventListener('languageChanged', this.handleLanguageChange);
    
    // Clean up tooltips
    this.disposeTooltips();
  }
};
</script>

<style scoped lang="scss">
.materials-tab {
  // Remove custom radio button styles since we don't need them anymore
  .table {
    th, td {
      &:focus-within {
        border-color: var(--cotalo-green);
      }
    }
  }
  
  input {
    &:focus {
      border-color: var(--cotalo-green);
    }
  }
}

// Force right alignment for all number inputs in the product-table
.product-table input[type='number'] {
  text-align: right !important;
}

.custom-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.6);
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
}
.custom-overlay-content {
  background: #23272b;
  color: #fff;
  padding: 2rem;
  border-radius: 8px;
  min-width: 600px;
  max-width: 98vw;
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
  position: relative;
}
.btn-close {
  position: absolute;
  top: 1rem;
  right: 1rem;
  color: #fff;
  background: transparent;
  border: none;
  font-size: 1.7rem;
  opacity: 0.7;
  transition: opacity 0.2s;
  box-shadow: none;
  outline: none;
}
.btn-close:hover, .btn-close:focus {
  opacity: 1;
  color: #fff;
  background: #23272b;
}
</style>