<template>
  <div class="materials-tab">
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row align-items-end">
            <div class="col-md-9 mb-3 mb-md-0">
              <div class="d-flex align-items-center mb-2">
                <label for="material-select" class="form-label mb-0 me-2">{{ translations.materials.select_material }}</label>
                <button 
                  type="button" 
                  class="btn btn-outline-success btn-sm"
                  data-bs-toggle="tooltip"
                  data-bs-placement="right"
                  data-bs-html="true"
                  :title="translations.materials_calculation_tooltip || '¿Cómo se calculan los costos de materiales?<br>• Piezas por material: Número de piezas que se pueden obtener de un pliego de material<br>• Total de pliegos: Cantidad estimada de pliegos necesarios para producir el producto<br>• Total en m²: Metros cuadrados totales de material requeridos (basado en tamaño y cantidad)<br>• Precio total: Costo total del material, calculado por área o peso, según corresponda'"
                >
                  <i class="fa fa-question-circle"></i>
                </button>
              </div>
              <multiselect
                v-model="materialIdForAdd"
                :options="availableMaterials"
                :track-by="'id'"
                :label="'description'"
                :placeholder="''"
                :disabled="!availableMaterials.length"
                @select="onMaterialSelect"
                :select-label="''"
                :remove-label="''"
                :deselect-label="''"
              />
            </div>
            
            <div class="col-md-3 d-grid">
              <button 
                class="btn btn-primary w-100" 
                @click="addMaterial" 
                :disabled="!canAdd"
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
    <div class="green-accent-panel mt-4" v-if="productMaterials.length">
      <div class="card">
        <div class="card-header">
          <div class="d-flex justify-content-between align-items-center">
            <h5 class="mb-0">
              <i class="fa fa-list me-2"></i>Lista de materiales
            </h5>
            <div class="d-flex align-items-center gap-3">
              <span class="text-light material-header-text">
                <i class="fa fa-cube me-1"></i>{{ productQuantity }} {{ translations.materials.pieces || 'pzas' }}
              </span>
              <span class="text-light material-header-text">
                <i class="fa fa-arrows-alt-h me-1"></i>{{ productWidth }} × {{ productLength }} cm
              </span>
            </div>
          </div>
        </div>
        <div class="card-body p-0">
          
          <!-- Desktop Table -->
          <div class="d-none d-md-block">
            <table class="table table-striped product-table mb-0">
              <thead>
                <tr>
                  <th style="width: 32%">{{ translations.materials.description }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.width }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.length }}</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.price }}</th>
                  <th style="width: 12%" class="text-end">Pzas</th>
                  <th style="width: 12%" class="text-end">Pliegos</th>
                  <th style="width: 12%" class="text-end">Peso</th>
                  <th style="width: 12%" class="text-end">m²</th>
                  <th style="width: 12%" class="text-end">{{ translations.materials.total_price }}</th>
                  <th style="width: 16%" class="text-center">{{ translations.materials.actions }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(material, index) in productMaterials" :key="index">
                  <td class="text-truncate" style="max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" :title="material.displayName || material.description">{{ material.displayName || material.description }}</td>
                  <td class="text-end">
                    <input 
                      type="number" 
                      class="form-control form-control-sm text-end" 
                      v-model.number="material.ancho" 
                      min="0"
                      step="0.1"
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
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
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
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
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
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
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                      title="Pzas"
                      data-toggle="tooltip"
                    />
                  </td>
                  <td class="text-end">{{ material.totalSheets }}</td>
                  <td class="text-end">
                    <span v-if="material.totalWeight && material.totalWeight > 0">{{ (material.totalWeight / 1000).toFixed(2) }}</span>
                    <span v-else>-</span>
                  </td>
                  <td class="text-end">
                    <span v-if="!isWeightBased(material)">{{ material.totalSquareMeters.toFixed(2) }}</span>
                    <span v-else>-</span>
                  </td>
                  <td class="text-end">
                    <span 
                      :title="' El costo del material se calcula automáticamente según el tipo de unidad configurada: por metro cuadrado (m²) o por peso (g/m²). La cantidad de pliegos se muestra solo como referencia visual.'"
                      data-bs-toggle="tooltip"
                      data-bs-placement="left"
                      style="cursor: help;"
                    >
                      {{ formatCurrency(material.totalPrice) }}
                      <i class="fa fa-info-circle ms-1 text-info tooltip-icon" style="font-size: 0.9em; opacity: 0.8;"></i>
                    </span>
                  </td>
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
                  <th :colspan="productMaterials.length ? 8 : 1" class="text-end">Costo total:</th>
                  <th class="text-end">{{ formatCurrency(totalCost) }}</th>
                  <th></th>
                </tr>
              </tfoot>
            </table>
          </div>
          
          <!-- Mobile Cards -->
          <div class="d-md-none">
            <div v-for="(material, index) in productMaterials" :key="index" class="material-card-mobile">
              <!-- Header with name and delete button -->
              <div class="material-header">
                <div class="material-name">
                  <i class="fa fa-box me-2"></i>
                  <span>{{ material.displayName || material.description }}</span>
                </div>
                <button 
                  class="btn btn-sm btn-outline-danger" 
                  @click="removeMaterial(index)"
                  :title="translations.materials.remove"
                >
                  <i class="fa fa-trash"></i>
                </button>
              </div>
              
              <!-- Main content grid -->
              <div class="material-content">
                <!-- Dimensions and Price row -->
                <div class="input-row">
                  <div class="input-group">
                    <span class="input-label"><i class="fa fa-arrows-alt-h"></i> Ancho</span>
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.ancho" 
                      min="0"
                      step="0.1"
                      :placeholder="'0.0'"
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                    />
                    <span class="input-unit">cm</span>
                  </div>
                  <div class="input-group">
                    <span class="input-label"><i class="fa fa-arrows-alt-v"></i> Largo</span>
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.largo" 
                      min="0"
                      step="0.1"
                      :placeholder="'0.0'"
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                    />
                    <span class="input-unit">cm</span>
                  </div>
                  <div class="input-group">
                    <span class="input-label"><i class="fa fa-dollar-sign"></i> Precio</span>
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.price" 
                      min="0"
                      step="0.01"
                      :placeholder="'0.00'"
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                    />
                    <span class="input-unit">$</span>
                  </div>
                </div>
                
                <!-- Quantity and Pieces row -->
                <div class="input-row">
                  <div class="input-group">
                    <span class="input-label"><i class="fa fa-hashtag"></i> Pzas/hoja</span>
                    <input 
                      type="number" 
                      class="form-control form-control-sm" 
                      v-model.number="material.piecesPerMaterial" 
                      min="1"
                      :placeholder="'1'"
                      @blur="updateMaterialCalculations({ index, updatePiecesPerMaterial: true, material })"
                    />
                    <span class="input-unit">pz</span>
                  </div>
                  <div class="input-group">
                    <span class="input-label"><i class="fa fa-file-alt"></i> Pliegos</span>
                    <span class="display-value">{{ material.totalSheets || 0 }}</span>
                    <span class="input-unit">pgs</span>
                  </div>
                  <div class="input-group">
                    <span class="input-label"><i class="fa fa-ruler-combined"></i> m²</span>
                    <span class="display-value">{{ (material.totalSquareMeters || 0).toFixed(2) }}</span>
                    <span class="input-unit">m²</span>
                  </div>
                </div>
                
                <!-- Total price row -->
                <div class="total-row">
                                      <span class="total-label">Costo total:</span>
                  <span 
                    class="total-value"
                    :title="'El costo del material se calcula con base en el área total usada (en m²), no por pliegos completos. La cantidad de pliegos mostrada es solo una referencia visual.'"
                    data-bs-toggle="tooltip"
                    data-bs-placement="top"
                    style="cursor: help;"
                  >
                    {{ formatCurrency(material.totalPrice) }}
                    <i class="fa fa-info-circle ms-1 text-info tooltip-icon" style="font-size: 0.9em; opacity: 0.8;"></i>
                  </span>
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
              :placeholder="''"
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
          <p><strong>{{ visualizationMaterial.displayName || visualizationMaterial.description }}</strong> ({{ Number(visualizationMaterial.ancho).toFixed(1) }}cm x {{ Number(visualizationMaterial.largo).toFixed(1) }}cm)</p>
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
import Multiselect from 'vue-multiselect'
import 'vue-multiselect/dist/vue-multiselect.min.css'

export default {
  name: 'MaterialsTab',
  components: {
    Multiselect,
  },
  emits: {
    'update:product-materials': null,
    'update:comments': null,
    'update:materials-cost': null,
    'material-calculation-changed': null,
    'remove-material-with-processes': null
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
    },
    productProcessesByMaterial: {
      type: Object,
      default: () => ({})
    }
  },
  data() {
    return {
      visualizationMaterial: null,
      materialIdForAdd: '',
      globalComments: this.comments,
    };
  },
  created() {
    // Remove the initial material selection since we don't need it anymore
    // Ensure backward compatibility for existing materials
    this.ensureMaterialInstanceIds();
  },
  computed: {
    canAdd() {
      return !!this.materialIdForAdd;
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
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value || 0);
    },
    onMaterialSelect(selectedOption) {
      if (!selectedOption) {
        return;
      }

      // Validate product dimensions and quantity
      if (!this.productQuantity || this.productQuantity <= 0) {
        window.showWarning('Por favor, especifica la cantidad de piezas del producto en la pestaña de información general');
        this.materialIdForAdd = null; // Reset selector
        return;
      }
      if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
        window.showWarning('Por favor, especifica el ancho y largo del producto en la pestaña de información general');
        this.materialIdForAdd = null; // Reset selector
        return;
      }

    },
    addMaterial() {
      if (!this.productWidth || this.productWidth <= 0 || !this.productLength || this.productLength <= 0) {
        window.showWarning('Por favor, especifica el ancho y largo del producto en la pestaña de información general');
        return;
      }

      if (!this.materialIdForAdd) return;

      const selectedMaterial = this.materialIdForAdd;
      
      // Count how many times this material has been added
      const existingMaterialsOfSameType = this.productMaterials.filter(mat => mat.id === selectedMaterial.id);
      const materialInstanceNumber = existingMaterialsOfSameType.length + 1;
      
      // Create a unique identifier for this material instance
      const materialInstanceId = `${selectedMaterial.id}_${materialInstanceNumber}`;
      
      // Create a new material object with all required properties
      const newMaterial = {
        ...selectedMaterial,
        materialInstanceId, // Unique identifier for this instance
        materialInstanceNumber, // Instance number for display
        displayName: `${selectedMaterial.description} (${materialInstanceNumber})`, // Display name with number
        piecesPerMaterial: 1,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalWeight: 0,
        totalPrice: 0
      };
      
      // Add the material to the array
      this.productMaterials.push(newMaterial);
      
      // Calculate the material properties
      const materialIndex = this.productMaterials.length - 1;
      this.updateMaterialCalculations({ 
        index: materialIndex, 
        updatePiecesPerMaterial: true, 
        material: newMaterial 
      });
      
      // Reset form
      this.materialIdForAdd = null;
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

      // Calculate total price based on unit type
      let totalPrice = 0;
      let totalWeight = 0;
      // Fix: always extract unit string for detection
      const unitStr = typeof material.unit === 'string'
        ? material.unit
        : (material.unit?.name || material.unit?.abbreviation || '');

      
      if (unitStr.toLowerCase().includes('grs/m2') || unitStr.toLowerCase().includes('grs/m²')) {
        // Weight-based pricing (grs/m²)
        const materialWeight = parseFloat(material.weight) || 0;
        totalWeight = totalSquareMeters * materialWeight; // grams
        totalPrice = (totalWeight / 1000) * (material.price || 0); // price per kg
      } else if (unitStr.toLowerCase().includes('m2') || unitStr.toLowerCase().includes('mt2')) {
        // Area-based pricing (m²)
        totalPrice = totalSquareMeters * (material.price || 0);
      } else {
        // Default: per sheet
        totalPrice = totalSheets * (material.price || 0);
      }
      material.totalPrice = totalPrice;

      // Update the material with new calculations
      const updatedMaterial = {
        ...material,
        piecesPerMaterial,
        totalSheets,
        totalSquareMeters,
        totalWeight,
        totalPrice
      };

      // Emit the calculation change event
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        totalSheets,
        totalSquareMeters,
        totalWeight,
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
      const materialToRemove = this.productMaterials[index];
      
      // Check if this material has processes assigned
      const materialId = materialToRemove.materialInstanceId || materialToRemove.id;
      
      // Try to find processes for this material with different ID formats
      let processesForMaterial = this.productProcessesByMaterial[materialId] || [];
      
      // If not found, try with string conversion
      if (processesForMaterial.length === 0) {
        processesForMaterial = this.productProcessesByMaterial[String(materialId)] || [];
      }
      
      // If still not found, try with number conversion
      if (processesForMaterial.length === 0) {
        processesForMaterial = this.productProcessesByMaterial[Number(materialId)] || [];
      }
      
      // If still not found, search through all keys to find a match by base ID
      if (processesForMaterial.length === 0) {
        const baseMaterialId = materialToRemove.id; // The original material ID without instance number
        for (const key in this.productProcessesByMaterial) {
          // Check if the key starts with the base material ID (for instance IDs like "371_1", "371_2")
          if (key.startsWith(baseMaterialId + '_') || key == baseMaterialId) {
            processesForMaterial = this.productProcessesByMaterial[key];
            break;
          }
        }
      }
      
      if (processesForMaterial.length > 0) {
        // Show confirmation dialog
        const confirmMessage = `El material "${materialToRemove.displayName || materialToRemove.description}" tiene ${processesForMaterial.length} proceso(s) asignado(s).\n\n¿Deseas eliminar el material y todos sus procesos asociados?`;
        
        if (!confirm(confirmMessage)) {
          return; // User cancelled
        }
        
        // Emit event to remove processes for this material
        this.$emit('remove-material-with-processes', {
          materialId: materialId,
          materialIndex: index,
          processesToRemove: processesForMaterial
        });
      } else {
        // No processes assigned, proceed with normal removal
        this.productMaterials.splice(index, 1);
        
        // Emit updates in the correct order
        this.$emit('update:product-materials', this.productMaterials);
        this.$emit('update:materials-cost', this.totalCost);
        this.$emit('material-calculation-changed', {
          materialId: materialToRemove.id,
          totalSheets: 0,
          totalSquareMeters: 0,
          totalPrice: 0,
          needsProcessRecalculation: true,
          needsPricingRecalculation: true
        });
      }
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
    },
    isWeightBased(material) {
      const unitStr = typeof material.unit === 'string'
        ? material.unit
        : (material.unit?.name || material.unit?.abbreviation || '');
      return unitStr.toLowerCase().includes('grs/m2') || unitStr.toLowerCase().includes('grs/m²');
    },
    ensureMaterialInstanceIds() {
      // Ensure all materials have the required properties for backward compatibility
      this.productMaterials.forEach((material, index) => {
        if (!material.materialInstanceId) {
          // For existing materials without instance IDs, create them
          const existingMaterialsOfSameType = this.productMaterials.filter(m => m.id === material.id);
          const materialInstanceNumber = existingMaterialsOfSameType.indexOf(material) + 1;
          const materialInstanceId = `${material.id}_${materialInstanceNumber}`;
          
          // Update the material with the new properties
          const updatedMaterial = {
            ...material,
            materialInstanceId,
            materialInstanceNumber,
            displayName: material.displayName || `${material.description} (${materialInstanceNumber})`
          };
          
          this.productMaterials[index] = updatedMaterial;
        }
      });
    }
  },
  watch: {
    comments(newValue) {
      this.globalComments = newValue;
    },
    productMaterials: {
      handler(newVal) {
        // Ensure material instance IDs are set for all materials
        this.ensureMaterialInstanceIds();
        // Reinitialize tooltips when materials change
        this.$nextTick(() => {
          this.initializeTooltips();
        });
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

// Tooltip icon styling
.tooltip-icon {
  color: #17a2b8 !important; // Bootstrap info color
  transition: all 0.2s ease;
  
  &:hover {
    color: #138496 !important; // Darker info color on hover
    opacity: 1 !important;
    transform: scale(1.1);
  }
}

// Ensure tooltip icon is visible in dark themes
[data-bs-theme="dark"] .tooltip-icon {
  color: #6ea8fe !important; // Light blue for dark theme
  
  &:hover {
    color: #93c5fd !important;
  }
}

// Mobile material cards styling
.material-card-mobile {
  background: var(--bs-card-bg);
  border: 1px solid var(--bs-border-color);
  border-radius: 0.5rem;
  margin-bottom: 1rem;
  overflow: hidden;
  
  .material-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.75rem 1rem;
    background: var(--bs-card-cap-bg);
    border-bottom: 1px solid var(--bs-border-color);
    
    .material-name {
      font-weight: 600;
      color: var(--bs-body-color);
      display: flex;
      align-items: center;
      
      i {
        color: var(--cotalo-green);
      }
    }
  }
  
  .material-content {
    padding: 1rem;
    
    .input-row {
      display: flex;
      gap: 0.75rem;
      margin-bottom: 0.75rem;
      
      .input-group {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        
        .input-label {
          font-size: 0.75rem;
          font-weight: 600;
          color: var(--bs-secondary);
          display: flex;
          align-items: center;
          gap: 0.25rem;
          
          i {
            color: var(--cotalo-green);
          }
        }
        
        .form-control {
          height: 2rem;
          font-size: 0.875rem;
          text-align: center;
          border-radius: 0.25rem;
          background: var(--bs-body-bg);
          color: var(--bs-body-color);
          border: 1px solid var(--bs-border-color);
          padding: 0.25rem 0.5rem;
          
          &:focus {
            border-color: var(--cotalo-green);
            box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25);
          }
          
          &::placeholder {
            color: var(--bs-secondary);
            opacity: 0.7;
          }
        }
        
        .display-value {
          height: 2rem;
          display: flex;
          align-items: center;
          justify-content: center;
          background: var(--bs-secondary-bg);
          border: 1px solid var(--bs-border-color);
          border-radius: 0.25rem;
          font-size: 0.875rem;
          font-weight: 600;
          color: var(--bs-body-color);
          min-width: 0;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        
        .input-unit {
          font-size: 0.75rem;
          color: var(--bs-secondary);
          text-align: center;
          font-weight: 500;
        }
      }
    }
    
    .total-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.75rem;
      background: rgba(66, 185, 131, 0.1);
      border-radius: 0.25rem;
      border: 1px solid rgba(66, 185, 131, 0.2);
      
      .total-label {
        font-weight: 700;
        color: var(--bs-body-color);
        font-size: 0.9rem;
      }
      
      .total-value {
        font-weight: 700;
        color: var(--cotalo-green);
        font-size: 1rem;
        display: flex;
        align-items: center;
        gap: 0.25rem;
      }
    }
  }
}

/* Material header text styling */
.material-header-text {
  font-size: 0.9rem;
  opacity: 0.9;
}

/* Mobile material header styling */
@media (max-width: 767.98px) {
  .material-header-text {
    font-size: 0.8rem;
  }
}

// Responsive adjustments for very small screens
@media (max-width: 480px) {
  .material-card-mobile {
    .material-content {
      padding: 0.75rem;
      
      .input-row {
        gap: 0.5rem;
        margin-bottom: 0.5rem;
        
        .input-group {
          .input-label {
            font-size: 0.7rem;
          }
          
          .form-control,
          .display-value {
            height: 1.75rem;
            font-size: 0.8rem;
          }
          
          .input-unit {
            font-size: 0.7rem;
          }
        }
      }
      
      .total-row {
        padding: 0.5rem;
        
        .total-label {
          font-size: 0.85rem;
        }
        
        .total-value {
          font-size: 0.9rem;
        }
      }
    }
  }
}
</style>