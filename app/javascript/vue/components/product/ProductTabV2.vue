<template>
  <div class="product-tab-v2">

    <!-- Basic Product Information -->
    <div class="green-accent-panel">
      <div class="card">
        <div class="card-body">
          <div class="row">
            <!-- Product Description -->
            <div class="col-md-6 mb-3">
              <label for="product-description" class="form-label text-success">Descripción del producto</label>
              <input 
                type="text" 
                id="product-description" 
                class="form-control" 
                v-model="product.description" 
                @input="updateProductDescription"
                placeholder="Ej: Tarjetas de presentación, Folletos, Etiquetas..."
                required
                autocomplete="off"
              />
            </div>

            <!-- Quantity -->
            <div class="col-md-2 mb-3">
              <label for="product-quantity" class="form-label text-success">Piezas</label>
              <input 
                type="text" 
                inputmode="decimal"
                id="product-quantity" 
                class="form-control" 
                v-model.number="product.data.general_info.quantity" 
                @change="handleQuantityChange"
                min="1" 
                required
              />
            </div>

            <!-- Width -->
            <div class="col-md-2 mb-3">
              <label for="product-width" class="form-label text-success">Ancho (cm)</label>
              <input 
                type="text" 
                inputmode="decimal"
                id="product-width" 
                class="form-control" 
                v-model.number="product.data.general_info.width" 
                @change="handleDimensionChange"
                step="0.1"
                min="0.1" 
                required
              />
            </div>

            <!-- Length -->
            <div class="col-md-2 mb-3">
              <label for="product-length" class="form-label text-success">Largo (cm)</label>
              <input 
                type="text" 
                inputmode="decimal"
                id="product-length" 
                class="form-control" 
                v-model.number="product.data.general_info.length" 
                @change="handleDimensionChange"
                step="0.1"
                min="0.1" 
                required
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Materials Section -->
    <div class="green-accent-panel mt-4">
      <div class="card">

        <!-- Header -->
        <div class="card-header">
          <div class="d-flex justify-content-between align-items-center">
            
            <!-- Title -->
            <h5 class="mb-0">
              <i class="fa fa-box me-2"></i>Materiales del producto
            </h5>

            <!-- Tooltip -->
            <button 
              class="btn btn-outline-success btn-sm"
              data-bs-toggle="tooltip"
              data-bs-placement="left"
              data-bs-html="true"
              data-bs-trigger="hover"
              tabindex="-1"
              :title="translations.materials_calculation_tooltip || '<strong>¿Cómo se calculan los costos de materiales?</strong><br><br><strong>Materiales por área (m²):</strong><br>• <u>Piezas por material</u>: Cantidad de piezas que se pueden obtener de un pliego<br>• <u>Total de pliegos</u>: Cantidad estimada de pliegos necesarios<br>• <u>Total en m²</u>: Metros cuadrados totales requeridos<br>• <u>Costo total</u>: Precio por m² × Total m²<br><br><strong>Materiales por peso (kg, g):</strong><br>• <u>Peso por pieza</u>: Peso individual de cada pieza<br>• <u>Peso total</u>: Peso total requerido para todas las piezas<br>• <u>Costo total</u>: Precio por kg/g × Peso total'">
              <i class="fa fa-question-circle"></i>
            </button>

          </div>
        </div>

        <div class="card-body">

          <!-- Add Material Section -->
          <div class="d-flex align-items-center gap-3 mb-4">
            
            <!-- Label -->
            <div class="d-flex align-items-center">
              <label for="material-select" class="form-label mb-0 me-2">Seleccionar material</label>
            </div>

            <!-- Materials Select -->
            <div class="flex-grow-1">
              <multiselect
                v-model="materialIdForAdd"
                :options="availableMaterials"
                :track-by="'id'"
                :label="'description'"
                :placeholder="'Selecciona un material existente o agrega uno aquí directamente'"
                :preselect-first="false"
                :tabindex="-1"
                :disabled="!availableMaterials.length"
                @select="onMaterialSelect"
                :select-label="''"
                :remove-label="''"
                :deselect-label="''"
              />
            </div>

            <!-- Link to materials CRUD -->
            <div>
              <a
                href="/materials"
                target="_blank"
                rel="noopener"
                class="btn btn-outline-success"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Abrir lista de materiales en una pestaña nueva"
              >
                <i class="fa fa-cubes"></i>
              </a>
            </div>

            <!-- Add Selected Material Button -->
            <div>
              <button 
                class="btn btn-primary" 
                @click="addMaterial" 
                :disabled="!canAdd"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Agregar material seleccionado"
              >
                <i class="fa fa-plus me-1"></i> Agregar
              </button>
            </div>

            <!-- Add Manual Material Button -->
            <div>
              <button 
                class="btn btn-primary" 
                @click="toggleManualMaterialForm"
                data-bs-toggle="tooltip"
                data-bs-placement="top"
                data-bs-trigger="hover"
                tabindex="-1"
                title="Agregar material manual"
              >
                <i class="fa fa-plus me-1"></i> Manual
              </button>
            </div>

          </div>

          <!-- Manual Material Inline Form -->
          <div v-if="showManualMaterialForm" class="manual-material-form border rounded p-3 mb-3 subtle-border" style="background:#2d2d2d;">
            <div class="row g-2 align-items-end">
              <div class="col-md-4">
                <label class="form-label">Descripción</label>
                <input type="text" class="form-control" v-model.trim="manualMaterial.description" placeholder="Describe el material" />
              </div>
              <div class="col-md-2">
                <label class="form-label">Unidad</label>
                <select class="form-select" v-model="manualMaterial.unit">
                  <option value="m2">m²</option>
                  <option value="grs/m2">grs/m²</option>
                  <option value="pliego">pliego</option>
                </select>
              </div>
              <div class="col-md-2">
                <label class="form-label">Ancho (cm)</label>
                <input type="text" inputmode="decimal" class="form-control" v-model.number="manualMaterial.ancho" />
              </div>
              <div class="col-md-2">
                <label class="form-label">Largo (cm)</label>
                <input type="text" inputmode="decimal" class="form-control" v-model.number="manualMaterial.largo" />
              </div>
              <div class="col-md-2">
                <label class="form-label">Precio unitario</label>
                <input type="text" inputmode="decimal" class="form-control" v-model.number="manualMaterial.cost" />
              </div>
              <div class="col-md-2" v-if="manualMaterial.unit === 'grs/m2'">
                <label class="form-label">Peso (grs/m²)</label>
                <input type="text" inputmode="decimal" class="form-control" v-model.number="manualMaterial.weight" />
              </div>
              <div class="col-md-auto ms-auto">
                <button class="btn btn-success me-2" @click="saveManualMaterial">
                  <i class="fa fa-check me-1"></i>Guardar
                </button>
                <button class="btn btn-outline-secondary" @click="cancelManualMaterial">
                  Cancelar
                </button>
              </div>
            </div>
          </div>

          <!-- No Materials Message -->
          <div v-if="!safeMaterials.length" class="text-center my-5">
            <p class="text-muted">No hay materiales agregados.</p>
          </div>

          <!-- Materials List -->
          <div v-if="safeMaterials.length" class="materials-list">
            
            <!-- Headers Row -->
            <div class="material-item mb-1">
              <div class="material-container headers-container" style="background: transparent !important; border: none !important; box-shadow: none !important;">
                <div class="material-header d-flex align-items-center p-3">
                  <!-- Collapse All Button -->
                  <button 
                    class="btn btn-sm btn-outline-success me-3" 
                    @click="toggleAllMaterials"
                    data-bs-toggle="tooltip"
                    data-bs-placement="top"
                    tabindex="-1"
                    :title="allMaterialsCollapsed ? 'Expandir todos' : 'Colapsar todos'"
                  >
                    <i :class="allMaterialsCollapsed ? 'fa fa-chevron-right' : 'fa fa-chevron-down'"></i>
                  </button>
                  
                  <!-- Material Description Column -->
                  <div class="flex-grow-1 me-2" style="padding-left:">
                    <strong class="text-success">Descripción</strong>
                  </div>
                  
                  <!-- Material Details Columns -->
                  <div class="d-flex align-items-center gap-2 me-2" style="min-width: 350px;">
                    <div class="text-end me-2" style="width: 70px;"><strong class="text-success">Ancho</strong></div>
                    <div class="text-end me-2" style="width: 70px;"><strong class="text-success">Largo</strong></div>
                    <div class="text-end me-2" style="width: 70px;"><strong class="text-success">Costo</strong></div>
                    <div class="text-end me-2" style="width: 45px;"><strong class="text-success">Pzas</strong></div>
                    <div class="text-end me-2" style="width: 60px;"><strong class="text-success">Pliegos</strong></div>
                    <div class="text-end me-2" style="width: 50px;"><strong class="text-success">Peso</strong></div>
                    <div class="text-end me-2" style="width: 60px;"><strong class="text-success">m²</strong></div>
                    <div class="text-end me-2" style="width: 90px;"><strong class="text-success">Costo total</strong></div>
                  </div>
                  
                  <!-- Action Buttons -->
                  <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="width: 140px;">
                    <strong class="text-success">Acciones</strong>
                  </div>
                  
                </div>
              </div>
            </div>
            
            <!-- Material Items -->
            <div v-for="(material, materialIndex) in safeMaterials" :key="material.materialInstanceId || material.id" class="material-item mb-3">
              
              <!-- Material Container -->
              <div class="material-container border rounded subtle-border">

                <!-- Material Header -->
                <div class="material-header d-flex align-items-center p-3">

                  <!-- Collapse Button -->
                  <button 
                    class="btn btn-sm btn-outline-secondary me-3" 
                    @click="toggleProcessesView(materialIndex)"
                    data-bs-toggle="tooltip"
                    data-bs-placement="top"
                    tabindex="-1"
                    :title="expandedProcesses[materialIndex] ? 'Ocultar procesos' : 'Mostrar procesos'">
                    <i :class="expandedProcesses[materialIndex] ? 'fa fa-chevron-down' : 'fa fa-chevron-right'"></i>
                  </button>
                  
                  <!-- Material Name -->
                  <div class="flex-grow-1 me-2" style="padding-left:">
                    <span style="font-weight: normal; color: var(--bs-body-color);">{{ material.displayName || material.description }}</span>
                  </div>
                  
                  <!-- Material Details Columns -->
                  <div class="d-flex align-items-center gap-2 me-2" style="min-width: 350px;">
                    
                    <!-- Width -->
                    <div class="d-flex align-items-center justify-content-end me-2" style="width: 70px;">
                      <input 
                        type="text" 
                        inputmode="decimal"
                        class="form-control form-control-sm text-end" 
                        v-model.number="material.ancho" 
                        min="0"
                        step="0.1"
                        @blur="updateMaterialCalculations(materialIndex, true)"
                        style="width: 60px;"
                      />
                    </div>

                    <!-- Length -->
                    <div class="d-flex align-items-center justify-content-end me-2" style="width: 70px;">
                      <input 
                        type="text" 
                        inputmode="decimal"
                        class="form-control form-control-sm text-end" 
                        v-model.number="material.largo" 
                        min="0"
                        step="0.1"
                        @blur="updateMaterialCalculations(materialIndex, true)"
                        style="width: 60px;"
                      />
                    </div>

                    <!-- Price (Cost) -->
                    <div class="d-flex align-items-center justify-content-end me-2" style="width: 70px;">
                      <input 
                        type="text" 
                        inputmode="decimal"
                        class="form-control form-control-sm text-end" 
                        :value="material.cost"
                        min="0"
                        step="0.01"
                        @input="onUnitPriceInput($event, material)"
                        @blur="updateMaterialCalculations(materialIndex, true)"
                        style="width: 60px;"
                      />
                    </div>

                    <!-- Pieces per material -->
                    <div class="text-end me-2" style="width: 45px;">
                      {{ material.piecesPerMaterial || 0 }}
                    </div>

                    <!-- Total sheets -->
                    <div class="text-end me-2" style="width: 60px;">
                      {{ material.totalSheets || 0 }}
                    </div>

                    <!-- Total weight -->
                    <div class="text-end me-2" style="width: 50px;">
                      {{ material.totalWeight && material.totalWeight > 0 ? (material.totalWeight / 1000).toFixed(2) : '-' }}
                    </div>

                    <!-- Total square meters -->
                    <div class="text-end me-2" style="width: 60px;" v-if="!isWeightBasedMaterial(material)">
                      {{ (material.totalSquareMeters || 0).toFixed(2) }}
                    </div>

                    <!-- Total square meters -->
                    <div class="text-end me-2" style="width: 60px;" v-else>
                      -
                    </div>

                    <!-- Total price -->
                    <div class="text-end me-2 price-column" style="width: 90px;">
                      {{ formatCurrency(material.totalPrice) }}
                    </div>
                  </div>
                  
                  <!-- Action Buttons -->
                  <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="width: 140px;">
                    
                    <!-- Simulation Button -->
                    <button 
                      class="btn btn-sm btn-outline-info" 
                      @click="showMaterialSimulation(material)"
                      data-bs-toggle="tooltip"
                      data-bs-placement="top"
                       data-bs-trigger="hover"
                       tabindex="-1"
                      data-bs-title="Ver simulación de piezas en material"
                      style="min-width: 40px;"
                    >
                      <i class="fa fa-calculator"></i>
                    </button>

                    <!-- Add Process Button -->
                    <button 
                      class="btn btn-sm btn-success" 
                      @click="toggleProcessForm(materialIndex)"
                      data-bs-toggle="tooltip"
                      data-bs-placement="top"
                       data-bs-trigger="hover"
                       tabindex="-1"
                      data-bs-title="Agregar proceso de fabricación a material"
                      style="min-width: 50px; background-color: #42b983 !important; border-color: #42b983 !important;"
                    >
                      <i class="fa fa-plus me-1"></i><i class="fa fa-cogs"></i>
                    </button>

                    <!-- Remove Material Button -->
                    <button 
                      class="btn btn-sm btn-outline-danger" 
                      @click="removeMaterial(materialIndex)"
                      data-bs-toggle="tooltip"
                      data-bs-placement="top"
                       tabindex="-1"
                      title="Eliminar"
                    >
                      <i class="fa fa-trash"></i>
                    </button>
                  </div>
                </div>
                
                <!-- Process Form Section -->
                <div v-if="expandedMaterialIndex === materialIndex" class="process-form-section p-3 border-top subtle-border-top">
                  
                  <!-- Process Form -->
                  <div class="row align-items-start gx-2">

                    <!-- Select Process -->
                    <div class="col mb-3">
                      <label class="form-label">Seleccionar proceso</label>
                      <multiselect
                        v-model="selectedProcessForMaterial[materialIndex]"
                        :options="filteredAvailableProcesses"
                        :track-by="'id'"
                        :label="'description'"
                        :placeholder="'Selecciona un proceso'"
                        :disabled="!filteredAvailableProcesses.length"
                        :tabindex="-1"
                        class="process-multiselect"
                      />
                    </div>

                    <!-- Veces -->
                    <div class="col-md-1 mb-3">
                      <label class="form-label">Veces</label>
                      <input 
                        type="text" 
                        inputmode="decimal"
                        class="form-control" 
                        v-model.number="processVeces[materialIndex]" 
                        min="1" 
                        step="1"
                        style="background-color: #2c3136 !important; border-color: #495057 !important; color: #e1e1e1 !important;"
                      />
                    </div>
                    
                    <!-- Side -->
                    <div class="col-md-1 mb-3">
                      <label class="form-label">Cara</label>
                      <select 
                        class="form-select" 
                        v-model="processSide[materialIndex]"
                        style="background-color: #2c3136 !important; border-color: #495057 !important; color: #e1e1e1 !important;"
                      >
                        <option value="front">Frente</option>
                        <option value="both">Ambas</option>
                      </select>
                    </div>
                    
                    <!-- Quick access to Processes CRUD (moved next to Add) -->
                    <div class="col-md-auto mb-3">
                      <div style="height: 32px;"></div>
                      <a
                        href="/manufacturing_processes"
                        target="_blank"
                        rel="noopener"
                        class="btn btn-outline-success"
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        tabindex="-1"
                        title="Abrir lista de procesos en una pestaña nueva"
                      >
                        <i class="fa fa-cogs"></i>
                      </a>
                    </div>
                    
                    <!-- Add Process Button -->
                    <div class="col-md-auto mb-3">
                      <div style="height: 32px;"></div>

                      <!-- Add Process Button -->
                      <button 
                        class="btn btn-primary" 
                        @click="addProcessToMaterial(materialIndex)"
                        :disabled="!selectedProcessForMaterial[materialIndex]"
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        tabindex="-1"
                        title="Agregar proceso"
                        style="background-color: #42b983 !important; border-color: #42b983 !important; color: white !important;"
                      >
                        <i class="fa fa-plus me-1"></i> Agregar
                      </button>
                    </div>
                    
                    <!-- Cancel Button -->
                    <div class="col-md-auto mb-3">
                      <div style="height: 32px;"></div>
                      <button 
                        class="btn btn-outline-success" 
                        @click="toggleProcessForm(materialIndex)"
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        tabindex="-1"
                        title="Cancelar"
                        style="color: #42b983 !important; border-color: #42b983 !important; background-color: transparent !important;"
                      >
                        Cancelar
                      </button>
                    </div>
                  </div>
                </div>
                
                <!-- Processes Table Headers -->
                <div v-if="material.processes && material.processes.length && expandedProcesses[materialIndex]" class="processes-table-headers mb-2">
                  <div class="d-flex align-items-center p-2 border-top subtle-border-top" style="background-color: #1a1a1a;">
                    
                    <!-- Process Description Column -->
                    <div class="flex-grow-1 me-2" style="padding-left: 2rem;">
                      <strong class="text-success">Descripción</strong>
                    </div>

                    <!-- Process Details Columns -->
                    <div class="d-flex align-items-center gap-4 me-3" style="min-width: 400px;">
                      <div class="text-end" style="width: 60px;"><strong class="text-success">Unidad</strong></div>
                      <div class="text-end" style="width: 70px;"><strong class="text-success">Veces</strong></div>
                      <div class="text-end" style="width: 100px;"><strong class="text-success">Costo</strong></div>
                      <div class="text-end" style="width: 120px;"><strong class="text-success">Cara</strong></div>
                      <div class="text-end" style="width: 100px;"><strong class="text-success">Costo total</strong></div>
                    </div>

                    <!-- Action Buttons --> 
                    <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="width: 100px;">
                      <strong class="text-success">Acciones</strong>
                    </div>
                  </div>
                </div>

                <!-- Processes List for this Material -->
                <div v-if="material.processes && material.processes.length && expandedProcesses[materialIndex]" class="processes-list">
                  <div v-for="(process, processIndex) in material.processes" :key="process.id || processIndex" class="process-item">
                     <div class="d-flex align-items-center p-2 border-top subtle-border-top" :class="{ 'rounded-bottom': processIndex === material.processes.length - 1 }" style="background-color: #1a1a1a;">
                      
                      <!-- Process Name -->
                      <div class="flex-grow-1 me-2" style="padding-left: 2rem;">
                        <span style="font-weight: normal; color: var(--bs-body-color);">{{ process.description }}</span>
                      </div>
                      
                      <div class="d-flex align-items-center gap-4 me-3" style="min-width: 400px;">
                         
                        <!-- Unit -->
                        <div class="text-end" style="width: 60px;">{{ process.unit || '-' }}</div>

                        <!-- Veces -->
                        <div class="text-end d-flex justify-content-end" style="width: 70px;">
                          <input 
                            type="text" 
                            inputmode="decimal"
                            class="form-control form-control-sm text-end" 
                            v-model.number="process.veces" 
                            min="1"
                            step="1"
                            @blur="updateProcessCalculations(materialIndex, processIndex)"
                            style="width: 60px;"
                          />
                        </div>

                        <!-- Unit Price -->
                        <div class="text-end d-flex justify-content-end" style="width: 100px;">
                          <input 
                            type="text" 
                            inputmode="decimal"
                            class="form-control form-control-sm text-end" 
                            v-model.number="process.unitPrice" 
                            min="0"
                            step="0.01"
                            @blur="updateProcessCalculations(materialIndex, processIndex)"
                            style="width: 80px;"
                          />
                        </div>

                        <!-- Side -->
                        <div class="text-end d-flex justify-content-end" style="width: 120px;">
                          <select 
                            class="form-select form-select-sm text-end" 
                            v-model="process.side"
                            @change="updateProcessCalculations(materialIndex, processIndex)"
                            style="width: 110px; font-size: 0.8rem;"
                          >
                            <option value="front">Frente</option>
                            <option value="both">Ambas</option>
                          </select>
                        </div>

                        <!-- Total Price --> 
                        <div class="text-end price-column" style="width: 100px; color: var(--bs-body-color);">
                          {{ formatCurrency(process.price) }}
                        </div>
                      </div>
                      
                      <!-- Action Button -->
                      <div class="d-flex align-items-center justify-content-end gap-2 me-1" style="width: 100px;">
                        <button 
                          class="btn btn-sm btn-outline-danger" 
                          @click="removeProcessFromMaterial(materialIndex, processIndex)"
                          data-bs-toggle="tooltip"
                          data-bs-placement="top"
                          data-bs-trigger="hover"
                          tabindex="-1"
                          title="Eliminar proceso"
                        >
                          <i class="fa fa-trash"></i>
                        </button>
                      </div>

                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>

  <!-- Product Comments Section (separate panel below materials) -->
  <div class="green-accent-panel mt-4">
    <div class="card">
      <div class="card-header">
        <h5 class="mb-0"><i class="fa fa-comments me-2"></i>Comentarios</h5>
      </div>
      <div class="card-body">
        <textarea
          class="form-control"
          rows="3"
          :value="(product.data.general_info && product.data.general_info.comments) || ''"
          @input="updateProductComments"
          placeholder="Notas internas del producto"></textarea>
      </div>
    </div>
  </div>

    <!-- Material Simulation Popup -->
    <div v-if="showSimulationPopup" class="modal fade show" style="display: block; background-color: rgba(0, 0, 0, 0.5);" tabindex="-1">
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content" style="background-color: #2d2d2d; border: 1px solid #6c757d;">
          <div class="modal-header" style="border-bottom: 1px solid #6c757d;">
            <h5 class="modal-title text-success">
              <i class="fa fa-calculator me-2"></i>Simulación de Material
            </h5>
            <button type="button" class="btn-close btn-close-white" @click="closeSimulationPopup"></button>
          </div>
          <div class="modal-body">
            <!-- Simulation Info -->
            <div class="row mb-4">
              <div class="col-md-6">
                <h6 class="text-success mb-3">Información del Material</h6>
                <div class="simulation-info">
                  <p class="text-light mb-2">
                    <strong>Material:</strong> {{ simulationData.materialName }}
                  </p>
                  <p class="text-light mb-2">
                    <strong>Dimensiones del material:</strong> {{ simulationData.materialWidth }}cm × {{ simulationData.materialLength }}cm
                  </p>
                  <p class="text-light mb-2">
                    <strong>Dimensiones de la pieza:</strong> {{ simulationData.pieceWidth }}cm × {{ simulationData.pieceLength }}cm
                  </p>
                  <p class="text-light mb-2">
                    <strong>Márgenes aplicados:</strong> {{ simulationData.marginWidth }}cm (ancho) × {{ simulationData.marginLength }}cm (largo)
                  </p>
                  <p class="text-light mb-2">
                    <strong>Área utilizable:</strong> {{ simulationData.usableWidth }}cm × {{ simulationData.usableLength }}cm
                  </p>
                </div>
              </div>
              <div class="col-md-6">
                <h6 class="text-success mb-3">Resultados de la Simulación</h6>
                <div class="simulation-results">
                  <p class="text-light mb-2">
                    <strong>Piezas por material:</strong> <span class="text-success">{{ simulationData.piecesPerMaterial }}</span>
                  </p>
                  <p class="text-light mb-2">
                    <strong>Orientación óptima:</strong> <span class="text-success">{{ simulationData.optimalOrientation }}</span>
                  </p>
                  <p class="text-light mb-2">
                    <strong>Área utilizada:</strong> <span class="text-success">{{ simulationData.usedAreaPercentage }}%</span>
                  </p>
                </div>
              </div>
            </div>

            <!-- Simulation Grid -->
            <div class="simulation-container">
              <h6 class="text-success mb-3">Visualización de la Disposición</h6>
              <div class="simulation-grid-wrapper" :style="{ maxWidth: '100%', overflow: 'auto', minHeight: '400px', display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '20px' }">
                <!-- Material dimensions display -->
                <div class="material-dimensions-display" :style="{ position: 'relative', display: 'inline-block' }">
                  <!-- Top dimension (width) -->
                  <div 
                    class="dimension-label dimension-top"
                    :style="{
                      position: 'absolute',
                      top: '-40px',
                      left: '50%',
                      transform: 'translateX(-50%)',
                      backgroundColor: '#2d2d2d',
                      color: '#42b983',
                      padding: '4px 8px',
                      borderRadius: '4px',
                      fontSize: '12px',
                      fontWeight: 'bold',
                      border: '1px solid #42b983',
                      whiteSpace: 'nowrap'
                    }"
                  >
                    {{ simulationData.materialWidth }}cm
                  </div>
                  
                  <!-- Left dimension (length) -->
                  <div 
                    class="dimension-label dimension-left"
                    :style="{
                      position: 'absolute',
                      left: '-50px',
                      top: '50%',
                      transform: 'translateY(-50%) rotate(-90deg)',
                      backgroundColor: '#2d2d2d',
                      color: '#42b983',
                      padding: '4px 8px',
                      borderRadius: '4px',
                      fontSize: '12px',
                      fontWeight: 'bold',
                      border: '1px solid #42b983',
                      whiteSpace: 'nowrap'
                    }"
                  >
                    {{ simulationData.materialLength }}cm
                  </div>
                  
                  <!-- Simulation grid -->
                  <div 
                    class="simulation-grid" 
                    :style="{
                      width: simulationData.gridWidth + 'px',
                      height: simulationData.gridHeight + 'px',
                      position: 'relative',
                      backgroundColor: '#495057',
                      border: '2px solid #6c757d',
                      margin: '0 auto'
                    }"
                  >
                    <!-- Material margins (shaded area) -->
                    <div 
                      v-if="simulationData.marginWidth > 0 || simulationData.marginLength > 0"
                      class="material-margins"
                      :style="{
                        position: 'absolute',
                        left: '0',
                        top: '0',
                        width: '100%',
                        height: '100%',
                        background: 'linear-gradient(45deg, #495057 25%, transparent 25%), linear-gradient(-45deg, #495057 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #495057 75%), linear-gradient(-45deg, transparent 75%, #495057 75%)',
                        backgroundSize: '20px 20px',
                        backgroundPosition: '0 0, 0 10px, 10px -10px, -10px 0px',
                        opacity: '0.3'
                      }"
                    ></div>
                    
                    <!-- Usable area (inner rectangle) -->
                    <div 
                      v-if="simulationData.marginWidth > 0 || simulationData.marginLength > 0"
                      class="usable-area"
                      :style="{
                        position: 'absolute',
                        left: (simulationData.marginWidth * (simulationData.gridWidth / simulationData.materialWidth)) + 'px',
                        top: (simulationData.marginLength * (simulationData.gridHeight / simulationData.materialLength)) + 'px',
                        width: (simulationData.usableWidth * (simulationData.gridWidth / simulationData.materialWidth)) + 'px',
                        height: (simulationData.usableLength * (simulationData.gridHeight / simulationData.materialLength)) + 'px',
                        backgroundColor: '#2d2d2d',
                        border: '1px solid #42b983',
                        boxSizing: 'border-box'
                      }"
                    ></div>
                    
                    <!-- Material pieces -->
                    <div 
                      v-for="(piece, index) in simulationData.pieces" 
                      :key="index"
                      class="simulation-piece"
                      :style="{
                        position: 'absolute',
                        left: piece.x + 'px',
                        top: piece.y + 'px',
                        width: piece.width + 'px',
                        height: piece.height + 'px',
                        backgroundColor: '#42b983',
                        border: '2px solid #000000',
                        boxSizing: 'border-box'
                      }"
                      :title="`Pieza ${index + 1}`"
                    ></div>
                  </div>
                </div>
              </div>
              
              <!-- Legend -->
              <div class="simulation-legend mt-3">
                <div class="d-flex justify-content-center gap-4">
                  <div class="d-flex align-items-center">
                    <div class="legend-item" style="width: 20px; height: 20px; background-color: #42b983; border: 2px solid #000000; margin-right: 8px;"></div>
                    <span class="text-light">Piezas</span>
                  </div>
                  <div class="d-flex align-items-center">
                    <div class="legend-item" style="width: 20px; height: 20px; background-color: #2d2d2d; border: 1px solid #42b983; margin-right: 8px;"></div>
                    <span class="text-light">Área utilizable</span>
                  </div>
                  <div class="d-flex align-items-center" v-if="simulationData.marginWidth > 0 || simulationData.marginLength > 0">
                    <div class="legend-item" style="width: 20px; height: 20px; background-color: #495057; border: 1px solid #6c757d; margin-right: 8px; opacity: 0.3;"></div>
                    <span class="text-light">Márgenes</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer" style="border-top: 1px solid #6c757d;">
            <button type="button" class="btn btn-success" @click="closeSimulationPopup">
              <i class="fa fa-check me-1"></i>Entendido
            </button>
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
  name: 'ProductTabV2',
  components: {
    Multiselect,
  },
  props: {
    product: {
      type: Object,
      required: true
    },
    isNew: {
      type: Boolean,
      default: false
    },
    availableMaterials: {
      type: Array,
      required: true
    },
    availableProcesses: {
      type: Array,
      required: true
    },
    translations: {
      type: Object,
      required: true
    },
    userConfig: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      materialIdForAdd: null,
      showManualMaterialForm: false,
      manualMaterial: {
        description: '',
        unit: 'm2',
        ancho: null,
        largo: null,
        cost: null,
        weight: null
      },
      expandedMaterialIndex: null,
      selectedProcessForMaterial: {},
      processVeces: {},
      processSide: {},
      expandedProcesses: {},
      quantityChangeTimeout: null,
      showSimulationPopup: false,
      simulationData: {
        materialName: '',
        materialWidth: 0,
        materialLength: 0,
        pieceWidth: 0,
        pieceLength: 0,
        piecesPerMaterial: 0,
        optimalOrientation: '',
        usedAreaPercentage: 0,
        gridWidth: 400,
        gridHeight: 400,
        pieces: [],
        marginWidth: 0,
        marginLength: 0,
        usableWidth: 0,
        usableLength: 0
      }
    };
  },
  emits: ['update:product', 'update:materials', 'material-calculation-changed', 'remove-material-with-processes'],
  computed: {
    safeMaterials() {
      const mats = this.product && this.product.data && this.product.data.materials;
      return Array.isArray(mats) ? mats : [];
    },
    canAdd() {
      return !!this.materialIdForAdd;
    },
    filteredAvailableProcesses() {
      // Filtrar procesos que NO tienen unidad "pieza"
      return this.availableProcesses.filter(process => 
        process.unit !== 'pieza' && process.unit !== 'piece'
      );
    },
    allMaterialsCollapsed() {
      // Verificar si todos los materiales están colapsados
      // Solo re-evaluar si hay materiales
      const materialsCount = this.product.data.materials ? this.product.data.materials.length : 0;
      if (materialsCount === 0) {
        return true;
      }
      // Solo depende de expandedProcesses, no de los materiales en sí
      for (let i = 0; i < materialsCount; i++) {
        if (this.expandedProcesses[i]) {
          return false;
        }
      }
      return true;
    }
  },
  mounted() {
    this.initializeTooltips();
    this.normalizeProcessSides();
  },
  methods: {
    toggleManualMaterialForm() {
      this.showManualMaterialForm = !this.showManualMaterialForm;
    },
    cancelManualMaterial() {
      this.showManualMaterialForm = false;
      this.manualMaterial = { description: '', unit: 'm2', ancho: null, largo: null, cost: null, weight: null };
    },
    saveManualMaterial() {
      const mm = this.manualMaterial;
      const errors = [];
      if (!mm.description || mm.description.trim().length === 0) errors.push('Descripción');
      if (!mm.unit) errors.push('Unidad');
      if (!mm.ancho || mm.ancho <= 0) errors.push('Ancho');
      if (!mm.largo || mm.largo <= 0) errors.push('Largo');
      if (!mm.cost || mm.cost <= 0) errors.push('Precio unitario');
      if (mm.unit === 'grs/m2' && (!mm.weight || mm.weight <= 0)) errors.push('Peso (grs/m²)');
      if (errors.length) {
        window.showWarning(`Completa: ${errors.join(', ')}`);
        return;
      }

      // Determine instance number among manual materials
      const existingManuals = this.product.data.materials.filter(m => m.id === 'manual');
      const materialInstanceNumber = existingManuals.length + 1;
      const materialInstanceId = `manual_${materialInstanceNumber}`;

      const newMaterial = {
        id: 'manual',
        materialInstanceId,
        materialInstanceNumber,
        displayName: `${mm.description} (${materialInstanceNumber})`,
        description: mm.description,
        unit: mm.unit,
        ancho: Number(mm.ancho) || 0,
        largo: Number(mm.largo) || 0,
        cost: Number(mm.cost) || 0,
        weight: mm.unit === 'grs/m2' ? (Number(mm.weight) || 0) : null,
        manual: true,
        piecesPerMaterial: 1,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalWeight: 0,
        totalPrice: 0
      };

      // Push and calculate like regular materials
      this.product.data.materials.push(newMaterial);
      const materialIndex = this.product.data.materials.length - 1;
      this.updateMaterialCalculations(materialIndex, false);
      this.$emit('update:materials', this.product.data.materials);

      // Reset form
      this.cancelManualMaterial();
    },
    updateProductComments(event) {
      const value = event.target.value;
      this.$emit('update:product', {
        data: {
          general_info: { comments: value }
        }
      });
    },
    getUnitPrice(material) {
      const price = material && material.cost;
      return parseFloat(price) || 0;
    },
    onUnitPriceInput(event, material) {
      const value = parseFloat(event.target.value);
      const numeric = isNaN(value) ? 0 : value;
      // Persistir solo en cost (sin alias)
      material.cost = numeric;
    },
    initializeTooltips() {
      // Inicializar tooltips de Bootstrap
      this.$nextTick(() => {
        const tooltipElements = this.$el.querySelectorAll('[data-bs-toggle="tooltip"]');
        tooltipElements.forEach(el => {
          if (window.bootstrap && window.bootstrap.Tooltip) {
            const t = new window.bootstrap.Tooltip(el);
            el.addEventListener('click', () => {
              // Ocultar tooltip al hacer click para evitar que quede pegado
              try {
                t.hide();
              } catch (e) {}
            });
            el.addEventListener('blur', () => {
              try { t.hide(); } catch (e) {}
            });
          }
        });
      });
    },
    
    // Map legacy 'back' values to 'front' to match current allowed options
    normalizeProcessSides() {
      try {
        const materials = (this.product && this.product.data && this.product.data.materials) || [];
        materials.forEach(material => {
          if (!Array.isArray(material.processes)) return;
          material.processes.forEach(process => {
            if (process && process.side === 'back') {
              process.side = 'front';
            }
          });
        });
        this.$forceUpdate();
      } catch (e) {
        // no-op
      }
    },
    
    formatCurrency(value) {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value || 0);
    },
    
    emitProductUpdate() {
      this.$emit('update:product', this.product);
    },
    
    updateProductDescription() {
      // Solo actualizar el producto, NO disparar recálculos
      this.$emit('update:product', this.product);
    },
    
    handleQuantityChange() {
      // Solo emitir actualización del producto, NO recalcular
      this.emitProductUpdate();
      
      // Debounce para evitar múltiples llamadas
      if (this.quantityChangeTimeout) {
        clearTimeout(this.quantityChangeTimeout);
      }
      
      this.quantityChangeTimeout = setTimeout(() => {
        // Disparar recálculo de materiales (que afecta procesos y pricing)
        this.recalculateAllMaterials();
      }, 100);
    },
    
    handleDimensionChange() {
      // Solo emitir actualización del producto, NO recalcular
      this.emitProductUpdate();
      // Disparar recálculo de materiales (que afecta procesos y pricing)
      this.recalculateAllMaterials();
    },
    
    onMaterialSelect(selectedOption) {
      if (!selectedOption) return;
      
      // Validate product dimensions and quantity
      if (!this.product.data.general_info.quantity || this.product.data.general_info.quantity <= 0) {
        window.showWarning('Por favor, especifica la cantidad de piezas del producto');
        this.materialIdForAdd = null;
        return;
      }
      if (!this.product.data.general_info.width || this.product.data.general_info.width <= 0 || 
          !this.product.data.general_info.length || this.product.data.general_info.length <= 0) {
        window.showWarning('Por favor, especifica el ancho y largo del producto');
        this.materialIdForAdd = null;
        return;
      }
    },
    
    addMaterial() {
      if (!this.materialIdForAdd) return;
      
      const selectedMaterial = this.materialIdForAdd;
      
      // Count how many times this material has been added
      const existingMaterialsOfSameType = this.product.data.materials.filter(mat => mat.id === selectedMaterial.id);
      const materialInstanceNumber = existingMaterialsOfSameType.length + 1;
      
      // Create a unique identifier for this material instance
      const materialInstanceId = `${selectedMaterial.id}_${materialInstanceNumber}`;
      
      // Create a new material object with all required properties
      const newMaterial = {
        ...selectedMaterial,
        materialInstanceId,
        materialInstanceNumber,
        displayName: `${selectedMaterial.description} (${materialInstanceNumber})`,
        // Keep both fields in sync during transition
        cost: selectedMaterial.cost ?? 0,
        piecesPerMaterial: 1,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalWeight: 0,
        totalPrice: 0
      };
      
      // Add the material to the array
      this.product.data.materials.push(newMaterial);
      
      // Calculate the material properties (sin emitir evento, ya que update:materials lo maneja)
      const materialIndex = this.product.data.materials.length - 1;
      this.updateMaterialCalculations(materialIndex, false);
      
      // Colapsar todos los materiales existentes
      this.product.data.materials.forEach((_, index) => {
        this.expandedProcesses[index] = false;
        if (this.expandedMaterialIndex === index) {
          this.expandedMaterialIndex = null;
        }
      });
      
      // Expandir solo el nuevo material
      this.expandedProcesses[materialIndex] = true;
      
      // Reset form
      this.materialIdForAdd = null;
      
      // Emit update - esto disparará el recálculo automáticamente
      this.$emit('update:materials', this.product.data.materials);
      
      // Show simulation automatically if user config allows it
      const showSimulation = this.userConfig && this.userConfig.show_material_simulation;
      if (showSimulation === true) {
        this.showMaterialSimulation(newMaterial);
        this.showSimulationPopup = true;
      }

      // Inicializar tooltips para el nuevo material
      this.$nextTick(() => {
        this.initializeTooltips();
      });
      
      // Calcular la simulación antes de mostrar el popup
      this.calculateSimulation(newMaterial);
    },
    
    updateMaterialCalculations(materialIndex, emitEvent = true) {
      const material = this.product.data.materials[materialIndex];
      if (!material) {
        return;
      }
      
      const productQuantity = this.product.data.general_info.quantity || 1;
      const productWidth = parseFloat(this.product.data.general_info.width) || 0;
      const productLength = parseFloat(this.product.data.general_info.length) || 0;
      
      // Add margins to product dimensions
      const effectiveProductWidth = productWidth + this.userConfig.width_margin;
      const effectiveProductLength = productLength + this.userConfig.length_margin;
      
      let piecesPerMaterial = material.piecesPerMaterial || 1;
      
      // Calculate pieces per material if dimensions are available
      if (effectiveProductWidth > 0 && effectiveProductLength > 0) {
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
      
      const unitStr = typeof material.unit === 'string'
        ? material.unit
        : (material.unit && material.unit.name || material.unit && material.unit.abbreviation || '');
      
      // Check if this is a weight-based material
      const isWeightBased = this.isWeightBasedMaterial(material);
      const isAreaBased = this.isAreaBasedMaterial(material);
      
      if (isWeightBased) {
        // Weight-based pricing (kg, g, etc.)
        const materialWeight = parseFloat(material.weight) || 0;
        totalWeight = totalSquareMeters * materialWeight; // grams
        totalPrice = (totalWeight / 1000) * this.getUnitPrice(material); // price per kg
      } else if (isAreaBased) {
        // Area-based pricing (m²)
        totalPrice = totalSquareMeters * this.getUnitPrice(material);
      } else {
        // Default: per sheet
        totalPrice = totalSheets * this.getUnitPrice(material);
      }
      
      // Update the material with new calculations
      material.piecesPerMaterial = piecesPerMaterial;
      material.totalSheets = totalSheets;
      material.totalSquareMeters = totalSquareMeters;
      material.totalWeight = totalWeight;
      material.totalPrice = totalPrice;
      

      
      // Force Vue to re-render the component
      this.$forceUpdate();
      
      // Emit the calculation change event only if requested
      if (emitEvent) {
        this.$emit('material-calculation-changed', {
          materialId: material.id,
          totalSheets,
          totalSquareMeters,
          totalWeight,
          totalPrice,
          needsProcessRecalculation: true,
          needsPricingRecalculation: true
        });
      }
    },
    
    removeMaterial(materialIndex) {
      this.product.data.materials.splice(materialIndex, 1);
      this.$emit('update:materials', this.product.data.materials);
    },
    

    
    recalculateAllMaterials() {
      // Recalcular todos los materiales sin emitir eventos individuales
      this.product.data.materials.forEach((_, index) => {
        this.updateMaterialCalculations(index, false);
      });
      
      // Emitir un solo evento después de recalcular todos los materiales
      this.$emit('material-calculation-changed', {
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });
    },
    
    toggleProcessForm(materialIndex) {
      if (this.expandedMaterialIndex === materialIndex) {
        this.expandedMaterialIndex = null;
        this.selectedProcessForMaterial[materialIndex] = null;
        this.processVeces[materialIndex] = 1;
        this.processSide[materialIndex] = 'front';
      } else {
        this.expandedMaterialIndex = materialIndex;
        this.selectedProcessForMaterial[materialIndex] = null;
        this.processVeces[materialIndex] = 1;
        this.processSide[materialIndex] = 'front';
      }
      // Re-initialize tooltips for dynamically shown buttons
      this.$nextTick(() => {
        this.initializeTooltips();
      });
    },
    
    toggleProcessesView(materialIndex) {
      this.expandedProcesses[materialIndex] = !this.expandedProcesses[materialIndex];
      // Si no hay procesos, solo cambia el icono pero no hace nada más
      this.$nextTick(() => {
        this.initializeTooltips();
      });
    },
    
    addProcessToMaterial(materialIndex) {
      const material = this.product.data.materials[materialIndex];
      const selectedProcess = this.selectedProcessForMaterial[materialIndex];
      
      if (!selectedProcess || !material) return;
      
      // Initialize processes array if it doesn't exist
      if (!material.processes) {
        material.processes = [];
      }
      
      // Calculate process price based on unit type
      const basePrice = parseFloat(selectedProcess.price) || 0;
      const veces = this.processVeces[materialIndex] || 1;
      const side = this.processSide[materialIndex] || 'front';
      const sideMultiplier = side === 'both' ? 2 : 1;
      
      let calculatedPrice = basePrice;
      const unitStr = typeof selectedProcess.unit === 'string'
        ? selectedProcess.unit
        : (selectedProcess.unit && selectedProcess.unit.name || selectedProcess.unit && selectedProcess.unit.abbreviation || '');
      
      if (unitStr.toLowerCase().includes('pieza')) {
        // Per piece
        const productQuantity = this.product.data.general_info.quantity || 1;
        calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
      } else if (unitStr.toLowerCase().includes('pliego')) {
        // Per sheet
        calculatedPrice = basePrice * (material.totalSheets || 0) * veces * sideMultiplier;
      } else if (unitStr.toLowerCase().includes('m2') || unitStr.toLowerCase().includes('mt2')) {
        // Per square meter - consider material type
        const isWeightBased = this.isWeightBasedMaterial(material);
        if (isWeightBased) {
          // For weight-based materials, use total weight (in kg) instead of square meters
          const totalWeightKg = (material.totalWeight || 0) / 1000;
          calculatedPrice = basePrice * totalWeightKg * veces * sideMultiplier;
        } else {
          // For area-based materials, use square meters
          calculatedPrice = basePrice * (material.totalSquareMeters || 0) * veces * sideMultiplier;
        }
      } else {
        // Default: per unit
        calculatedPrice = basePrice * veces * sideMultiplier;
      }
      
      // Create new process object
      const newProcess = {
        id: selectedProcess.id,
        description: selectedProcess.description,
        unit: unitStr,
        unitPrice: basePrice,
        veces: veces,
        side: side,
        price: calculatedPrice,
        materialId: material.materialInstanceId || material.id
      };
      
      // Add process to material
      material.processes.push(newProcess);
      
      // Reset form
      this.selectedProcessForMaterial[materialIndex] = null;
      this.processVeces[materialIndex] = 1;
      this.processSide[materialIndex] = 'front';
      this.expandedMaterialIndex = null;
      
      // Auto-expand processes view when adding a process
      this.expandedProcesses[materialIndex] = true;
      
      // Emit updates
      this.$emit('update:materials', this.product.data.materials);
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        needsProcessRecalculation: true,
        needsPricingRecalculation: false  // No recalcular materiales, solo procesos
      });
      // Ensure tooltips exist for new action buttons
      this.$nextTick(() => {
        this.initializeTooltips();
      });
    },
    
    removeProcessFromMaterial(materialIndex, processIndex) {
      const material = this.product.data.materials[materialIndex];
      if (!material || !material.processes) return;
      
      material.processes.splice(processIndex, 1);
      
      // Emit updates
      this.$emit('update:materials', this.product.data.materials);
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });
      this.$nextTick(() => {
        this.initializeTooltips();
      });
    },
    
    getSideLabel(side) {
      const labels = {
        front: 'Frente',
        back: 'Reverso',
        both: 'Ambas'
      };
      return labels[side] || side;
    },
    
    updateProcessCalculations(materialIndex, processIndex) {
      const material = this.product.data.materials[materialIndex];
      if (!material || !material.processes || !material.processes[processIndex]) {
        return;
      }
      
      const process = material.processes[processIndex];
      const productQuantity = this.product.data.general_info.quantity || 1;
      const veces = parseInt(process.veces) || 1;
      const basePrice = parseFloat(process.unitPrice) || 0;
      
      // Calculate side multiplier
      let sideMultiplier = 1;
      if (process.side === 'both') {
        sideMultiplier = 2;
      }
      
      // Calculate process price based on unit type
      let calculatedPrice = 0;
      const unitStr = typeof process.unit === 'string' ? process.unit : (process.unit && process.unit.name || '');
      
      if (unitStr.toLowerCase().includes('m2') || unitStr.toLowerCase().includes('mt2')) {
        // Area-based process
        if (this.isWeightBasedMaterial(material)) {
          // For weight-based materials, use total weight in kg
          const totalWeightKg = (material.totalWeight || 0) / 1000;
          calculatedPrice = basePrice * totalWeightKg * veces * sideMultiplier;
        } else {
          // For area-based materials, use square meters
          calculatedPrice = basePrice * (material.totalSquareMeters || 0) * veces * sideMultiplier;
        }
      } else {
        // Default: per unit
        calculatedPrice = basePrice * veces * sideMultiplier;
      }
      
      // Update the process price
      process.price = calculatedPrice;
      
      // Force Vue to re-render
      this.$forceUpdate();
      
      // Emit the calculation change event
      this.$emit('material-calculation-changed', {
        materialId: material.id,
        needsProcessRecalculation: true,
        needsPricingRecalculation: true
      });
    },

         toggleAllMaterials() {
       const shouldCollapse = !this.allMaterialsCollapsed;
       this.product.data.materials.forEach((_, index) => {
         this.expandedProcesses[index] = !shouldCollapse;
       });
     },
     
       // Check if this material uses weight-based pricing (kg, g, gr, etc.)
  isWeightBasedMaterial(material) {
    if (!material.unit) return false;
    
    let unitName = '';
    let unitAbbr = '';
    
    // Handle both object and string unit formats
    if (typeof material.unit === 'string') {
      unitName = material.unit.toLowerCase();
      unitAbbr = material.unit.toLowerCase();
    } else if (material.unit && typeof material.unit === 'object') {
      unitName = (material.unit.name || '').toLowerCase();
      unitAbbr = (material.unit.abbreviation || '').toLowerCase();
    }
    
    // Check for weight units (exact matches to avoid false positives)
    const weightUnits = ['kg', 'g', 'gr', 'gramo', 'gramos', 'kilo', 'kilos', 'kilogramo', 'kilogramos'];
    const weightMatch = weightUnits.some(wu => unitName === wu || unitAbbr === wu);
    const grsMatch = unitName.includes('grs/m2') || unitAbbr.includes('grs/m2');
    
    return weightMatch || grsMatch;
  },
     
       // Check if this material uses area-based pricing (m²)
  isAreaBasedMaterial(material) {
    if (!material.unit) return false;
    
    let unitName = '';
    let unitAbbr = '';
    
    // Handle both object and string unit formats
    if (typeof material.unit === 'string') {
      unitName = material.unit.toLowerCase();
      unitAbbr = material.unit.toLowerCase();
    } else if (material.unit && typeof material.unit === 'object') {
      unitName = (material.unit.name || '').toLowerCase();
      unitAbbr = (material.unit.abbreviation || '').toLowerCase();
    }
    
    // Check for area units
    const areaUnits = ['m2', 'mt2', 'm²', 'mt²', 'metro cuadrado', 'metros cuadrados'];
    return areaUnits.some(au => unitName.includes(au) || unitAbbr.includes(au));
  },
  
  // Método para cerrar el popup
  closeSimulationPopup() {
    this.showSimulationPopup = false;
  },
  
  // Método para calcular la simulación de piezas en el material
  calculateSimulation(material) {
    const productWidth = parseFloat(this.product.data.general_info.width) || 0;
    const productLength = parseFloat(this.product.data.general_info.length) || 0;
    const materialWidth = parseFloat(material.ancho) || 0;
    const materialLength = parseFloat(material.largo) || 0;
    const widthMargin = this.userConfig.width_margin || 0;
    const lengthMargin = this.userConfig.length_margin || 0;
    
    if (productWidth <= 0 || productLength <= 0 || materialWidth <= 0 || materialLength <= 0) {
      return;
    }
    
    // Calculate usable area by subtracting margins from all sides
    const usableMaterialWidth = materialWidth - (widthMargin * 2);
    const usableMaterialLength = materialLength - (lengthMargin * 2);
    
    // Check if usable area is valid
    if (usableMaterialWidth <= 0 || usableMaterialLength <= 0) {
      return;
    }
    
    // Calculate pieces in both orientations using the usable area
    const horizontalPieces = Math.floor(usableMaterialWidth / productWidth);
    const verticalPieces = Math.floor(usableMaterialLength / productLength);
    const piecesNormal = horizontalPieces * verticalPieces;
    
    const horizontalPiecesAlt = Math.floor(usableMaterialWidth / productLength);
    const verticalPiecesAlt = Math.floor(usableMaterialLength / productWidth);
    const piecesRotated = horizontalPiecesAlt * verticalPiecesAlt;
    
    // Determine optimal orientation
    let optimalOrientation, piecesPerMaterial, pieceWidth, pieceLength;
    
    if (piecesNormal >= piecesRotated) {
      optimalOrientation = 'Normal';
      piecesPerMaterial = piecesNormal;
      pieceWidth = productWidth;
      pieceLength = productLength;
    } else {
      optimalOrientation = 'Rotada 90°';
      piecesPerMaterial = piecesRotated;
      pieceWidth = productLength;
      pieceLength = productWidth;
    }
    
    // Set maximum grid dimensions for display
    const maxGridSize = 400;
    const gridWidth = Math.min(maxGridSize, materialWidth * 2);
    const gridHeight = Math.min(maxGridSize, materialLength * 2);
    
    // Calculate scale factors to fit the material in the grid
    const scaleX = gridWidth / materialWidth;
    const scaleY = gridHeight / materialLength;
    const scale = Math.min(scaleX, scaleY);
    
    // Calculate scaled dimensions
    const scaledMaterialWidth = materialWidth * scale;
    const scaledMaterialLength = materialLength * scale;
    const scaledUsableWidth = usableMaterialWidth * scale;
    const scaledUsableLength = usableMaterialLength * scale;
    const scaledPieceWidth = pieceWidth * scale;
    const scaledPieceLength = pieceLength * scale;
    const scaledMarginWidth = widthMargin * scale;
    const scaledMarginLength = lengthMargin * scale;
    
    // Generate pieces positions within the usable area
    const pieces = [];
    const maxPiecesPerRow = Math.floor(scaledUsableWidth / scaledPieceWidth);
    const maxPiecesPerCol = Math.floor(scaledUsableLength / scaledPieceLength);
    
    for (let row = 0; row < maxPiecesPerCol; row++) {
      for (let col = 0; col < maxPiecesPerRow; col++) {
        if (pieces.length < piecesPerMaterial) {
          pieces.push({
            x: scaledMarginWidth + (col * scaledPieceWidth),
            y: scaledMarginLength + (row * scaledPieceLength),
            width: scaledPieceWidth,
            height: scaledPieceLength
          });
        }
      }
    }
    
    // Calculate used area percentage (only within usable area)
    const totalMaterialArea = materialWidth * materialLength;
    const usableArea = usableMaterialWidth * usableMaterialLength;
    const usedArea = piecesPerMaterial * productWidth * productLength;
    const usedAreaPercentage = usableArea > 0 ? Math.round((usedArea / usableArea) * 100) : 0;
    
    // Update simulation data
    this.simulationData = {
      materialName: material.displayName || material.description,
      materialWidth: materialWidth,
      materialLength: materialLength,
      pieceWidth: productWidth,
      pieceLength: productLength,
      piecesPerMaterial: piecesPerMaterial,
      optimalOrientation: optimalOrientation,
      usedAreaPercentage: usedAreaPercentage,
      gridWidth: scaledMaterialWidth,
      gridHeight: scaledMaterialLength,
      pieces: pieces,
      // Add margin information for display
      marginWidth: widthMargin,
      marginLength: lengthMargin,
      usableWidth: usableMaterialWidth,
      usableLength: usableMaterialLength
    };
  },

  showMaterialSimulation(material) {
    this.calculateSimulation(material);
    this.showSimulationPopup = true;
  }
},
  // Los watchers ya no son necesarios porque los recálculos se disparan directamente
  // en handleQuantityChange() y handleDimensionChange()
  // watch: {
  //   'product.data.general_info.quantity'() {
  //     this.recalculateAllMaterials();
  //   },
  //   'product.data.general_info.width'() {
  //     this.recalculateAllMaterials();
  //   },
  //   'product.data.general_info.length'() {
  //     this.recalculateAllMaterials();
  //   }
  // }
};
</script>

<style scoped>
.product-tab-v2 {
  /* Estilos para bordes sutiles */
  .subtle-border {
    border-color: #6c757d !important; /* Color gris sutil como el selector */
  }
  
  .subtle-border-top {
    border-top-color: #6c757d !important; /* Color gris sutil para separadores */
  }
  
  /* Estilos para esquinas circulares */
  .rounded-bottom {
    border-bottom-left-radius: 0.5rem !important;
    border-bottom-right-radius: 0.5rem !important;
  }
  
  /* Asegurar que el último elemento del contenedor tenga esquinas circulares */
  .material-container > *:last-child {
    border-bottom-left-radius: 0.5rem !important;
    border-bottom-right-radius: 0.5rem !important;
  }
  
  .material-item {
    .material-container {
      background: #2d2d2d !important;
      border: 1px solid #6c757d !important; /* Borde sutil en lugar de var(--bs-border-color) */
      border-radius: 0.5rem !important;
      overflow: visible !important; /* Cambiado a visible para dropdowns */
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5) !important;
    }
    
    /* Asegurar que el fondo sea transparente */
    .materials-list {
      background: transparent;
      padding: 1rem;
      border-radius: 0.5rem;
    }
    
    .material-header {
      background: transparent !important;
      color: #ffffff !important;
    }
    
    .material-name {
      font-weight: 600;
      color: #ffffff !important;
    }
    
    .material-specs {
      font-size: 0.875rem;
    }
    
    .material-info {
      flex-grow: 1;
    }
    
    .material-description-column {
      overflow: hidden;
      
      .material-name {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        max-width: 100%;
        display: block;
      }
    }
    
    .collapse-button-spacer {
      width: 40px; /* Ancho del botón btn-sm + padding + border */
      height: 32px; /* Alto del botón btn-sm */
      flex-shrink: 0;
    }
    
    .material-calculations {
      font-size: 0.875rem;
      
      div {
        color: #ffffff !important;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        word-break: keep-all;
        line-height: 1.2;
      }
    }
    
    .price-column {
      font-family: 'Courier New', monospace;
      font-weight: 600;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    /* Asegurar que los dropdowns se muestren por encima de otros elementos */
    .process-form-section {
      overflow: visible !important;
      position: relative;
      z-index: 1000;
    }
    

    
    /* Headers container without border */
    .headers-container {
      border: none !important;
      box-shadow: none !important;
      background: transparent !important;
    }
    
    /* Processes table headers */
    .processes-table-headers {
      background: #1a1a1a !important;
    }
    
    /* Force green background for add process button */
    .process-form-section .btn-primary {
      background-color: #28a745 !important;
      border-color: #28a745 !important;
      color: white !important;
    }
    
    .process-form-section .btn-primary:hover {
      background-color: #218838 !important;
      border-color: #1e7e34 !important;
    }
    
    :deep(.multiselect) {
      z-index: 10000 !important;
      position: relative;
      background-color: #2c3136 !important;
      border-color: #495057 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.multiselect__tags) {
      background-color: #2c3136 !important;
      border-color: #495057 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.multiselect__single) {
      background-color: #2c3136 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.multiselect__input) {
      background-color: #2c3136 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.multiselect__content-wrapper) {
      z-index: 10000 !important;
      max-height: 200px !important;
      position: absolute !important;
      top: 100% !important;
      left: 0 !important;
      right: 0 !important;
      overflow: visible !important;
    }
    
    :deep(.multiselect__content) {
      z-index: 10000 !important;
      overflow: visible !important;
    }
    
    :deep(.multiselect__list) {
      z-index: 10000 !important;
      overflow: visible !important;
    }
    
    /* Estilos para form-select para que coincida con form-control */
    :deep(.form-select) {
      color: #e1e1e1 !important;
      background-color: #2c3136 !important;
      border: 1px solid #495057 !important;
      border-radius: 4px !important;
    }
    
    :deep(.form-select:focus) {
      border-color: #42b983 !important;
      background-color: #2c3136 !important;
      color: #e1e1e1 !important;
      box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25) !important;
    }
    
    /* Ocultar el mensaje de ayuda "Press enter to select" */
    :deep(.multiselect__option--highlight) {
      background: var(--bs-primary) !important;
    }
    
    :deep(.multiselect__option--highlight::after) {
      display: none !important;
    }
    
    :deep(.multiselect__option--highlight .multiselect__option--selected) {
      display: none !important;
    }
    
    .process-form-section {
      background: #2d2d2d !important;
      border-top: 1px solid #6c757d; /* Borde sutil consistente */
      color: #ffffff !important;
    }
    
    .processes-list {
      background: #2d2d2d !important;
      
      .process-item {
        background: #2d2d2d !important;
        color: #ffffff !important;
        
        .border-top {
          border-color: #6c757d !important; /* Borde sutil para separadores de procesos */
        }
        
        .process-row {
          padding-left: 3rem; /* Indentación para mostrar dependencia del material */
        }
        
        .process-name {
          color: #ffffff !important;
          font-weight: normal; /* Quitar bold */
        }
        
        .process-price {
          color: #ffffff !important; /* Mismo color que el resto de textos */
        }
      }
    }
    
    /* Force right alignment for material table columns */
    .material-container .text-end {
      text-align: right !important;
    }
    
    .material-container .d-flex.justify-content-end .text-end {
      text-align: right !important;
    }
    
    /* Dark background for process form controls to match header */
    .processes-list .form-control,
    .processes-list .form-select {
      background-color: #1a1a1a !important;
      border-color: #495057 !important;
      color: #e1e1e1 !important;
    }
    
    .processes-list .form-control:focus,
    .processes-list .form-select:focus {
      background-color: #1a1a1a !important;
      border-color: #42b983 !important;
      color: #e1e1e1 !important;
      box-shadow: 0 0 0 0.2rem rgba(66, 185, 131, 0.25) !important;
    }

    /* Estilos específicos para el multiselect de procesos */
    :deep(.process-multiselect) {
      background-color: #2c3136 !important;
      border-color: #495057 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.process-multiselect .multiselect__tags) {
      background-color: #2c3136 !important;
      border-color: #495057 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.process-multiselect .multiselect__single) {
      background-color: #2c3136 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.process-multiselect .multiselect__input) {
      background-color: #2c3136 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.process-multiselect .multiselect__content-wrapper) {
      background-color: #2c3136 !important;
      border-color: #495057 !important;
    }
    
    :deep(.process-multiselect .multiselect__option) {
      background-color: #2c3136 !important;
      color: #e1e1e1 !important;
    }
    
    :deep(.process-multiselect .multiselect__option--highlight) {
      background-color: #42b983 !important;
      color: white !important;
    }
  }
}

/* Estilos para la simulación */
.simulation-container {
  .simulation-grid-wrapper {
    border: 1px solid #6c757d;
    border-radius: 8px;
    padding: 15px;
    background-color: #1a1a1a;
    min-height: 400px;
    display: flex;
    justify-content: center;
    align-items: center;
  }
  
  .simulation-grid {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    border-radius: 4px;
  }
  
  .simulation-piece {
    transition: all 0.3s ease;
    border-radius: 2px;
  }
  
  .simulation-piece:hover {
    transform: scale(1.05);
    box-shadow: 0 2px 8px rgba(66, 185, 131, 0.5);
    z-index: 10;
  }
  
  .simulation-legend {
    .legend-item {
      border-radius: 2px;
    }
  }
  
  .simulation-info, .simulation-results {
    background-color: #1a1a1a;
    padding: 15px;
    border-radius: 8px;
    border: 1px solid #6c757d;
  }
  
  .material-dimensions-display {
    .dimension-label {
      z-index: 1000;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
    }
    
    .dimension-top {
      transform-origin: center;
    }
    
    .dimension-left {
      transform-origin: center;
    }
  }
}
</style> 