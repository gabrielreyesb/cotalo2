// Product Form V3 - Single Page Progressive Form JavaScript

// Product Form V3 script loaded

// State management for V3 (5 steps instead of 6)
const formState = {
  currentStep: 1,
  totalSteps: 5,
  sectionsCompleted: [],
  productData: {
    general_info: {},
    materials_with_processes: [], // New structure: materials with their processes
    global_processes: [],          // Global processes (was just "processes")
    extras: [],
    pricing: {}
  },
  availableMaterials: [],
  availableProcesses: [],
  availableExtras: [],
  availableUnits: []
};

// Helper functions for calculations (based on V2 logic)
function isWeightBasedMaterial(material) {
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
}

function isAreaBasedMaterial(material) {
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
}

function calculateMaterialData(material, productQuantity = 1, productWidth = 0, productLength = 0) {
  console.log('🧮 Calculating material data for:', material.description);
  
  // Get material dimensions
  const materialWidth = parseFloat(material.ancho) || 0;
  const materialLength = parseFloat(material.largo) || 0;
  const materialPrice = parseFloat(material.cost || material.price) || 0;
  const materialWeight = parseFloat(material.weight) || 0;
  
  // Calculate pieces per material
  let piecesPerMaterial = 1;
  if (productWidth > 0 && productLength > 0 && materialWidth > 0 && materialLength > 0) {
    // Calculate how many pieces fit horizontally and vertically
    const horizontalPieces = Math.floor(materialWidth / productWidth);
    const verticalPieces = Math.floor(materialLength / productLength);
    
    // Try the other orientation as well
    const horizontalPiecesAlt = Math.floor(materialWidth / productLength);
    const verticalPiecesAlt = Math.floor(materialLength / productWidth);
    
    // Use the orientation that fits more pieces
    piecesPerMaterial = Math.max(
      horizontalPieces * verticalPieces,
      horizontalPiecesAlt * verticalPiecesAlt
    );
  }
  
  // Calculate total sheets needed
  const totalSheets = piecesPerMaterial > 0 ? Math.ceil(productQuantity / piecesPerMaterial) : 0;
  
  // Calculate total square meters
  const totalSquareMeters = totalSheets * (materialWidth * materialLength) / 10000; // convert cm² to m²
  
  // Calculate total price based on unit type
  let totalPrice = 0;
  let totalWeight = 0;
  
  const isWeightBased = isWeightBasedMaterial(material);
  const isAreaBased = isAreaBasedMaterial(material);
  
  if (isWeightBased) {
    // Weight-based pricing (kg, g, etc.)
    totalWeight = totalSquareMeters * materialWeight; // grams
    totalPrice = (totalWeight / 1000) * materialPrice; // price per kg
  } else if (isAreaBased) {
    // Area-based pricing (m²)
    totalPrice = totalSquareMeters * materialPrice;
  } else {
    // Default: per sheet
    totalPrice = totalSheets * materialPrice;
  }
  
  return {
    piecesPerMaterial,
    totalSheets,
    totalSquareMeters: totalSquareMeters.toFixed(2),
    totalWeight: totalWeight > 0 ? (totalWeight / 1000).toFixed(2) : '-',
    totalPrice: totalPrice.toFixed(2),
    isWeightBased,
    isAreaBased
  };
}

function formatCurrency(amount) {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount);
}

// Global initialization function
function initializeV3Form() {
  // Don't initialize if we're on a Quote2s page
  if (window.location.pathname.includes('/quote2s')) {
    console.log('ℹ️ V3 form not needed on Quote2s page');
    return;
  }
  
  const form = document.getElementById('product-form-v3');
  
  if (!form) {
    console.error('❌ V3 form not found on this page');
    return;
  }
  updateProgressIndicator();
  bindEventListeners();
  
  loadMaterials();
  loadManufacturingProcesses();
  loadExtras();
  loadUnits();
  
  // Initial calculation
  setTimeout(() => {
    triggerRecalculation();
    bindPercentageInputEvents();
  }, 1000);
}

// Initialize after page loads
setTimeout(() => {
  initializeV3Form();
}, 1000);

// Also try on DOMContentLoaded as backup
document.addEventListener('DOMContentLoaded', function() {
  console.log('🎯 DOM Content Loaded for V3');
  setTimeout(() => {
    initializeV3Form();
  }, 500);
});

// Core functions for V3 form
function updateProgressIndicator() {
  // Update current step text
  const currentStepSpan = document.getElementById('current-step');
  if (currentStepSpan) {
    currentStepSpan.textContent = formState.currentStep;
  }
  
  // Update sidebar step indicators
  const stepItems = document.querySelectorAll('.step-item');
  
  stepItems.forEach((item, index) => {
    const stepNumber = index + 1;
    
    // Remove all states first
    item.classList.remove('active', 'completed');
    
    if (stepNumber < formState.currentStep) {
      // Completed step
      item.classList.add('completed');
    } else if (stepNumber === formState.currentStep) {
      // Current active step
      item.classList.add('active');
    }
    // Future steps remain with no class
  });
}

function bindEventListeners() {
  
  // Bind material addition
  const addMaterialBtn = document.getElementById('add-material-btn');
  if (addMaterialBtn) {
    addMaterialBtn.addEventListener('click', addMaterialWithProcesses);
  }
  
  // Bind manual material addition
  const addNewMaterialBtn = document.getElementById('add-new-material-btn');
  if (addNewMaterialBtn) {
    addNewMaterialBtn.addEventListener('click', addManualMaterial);
  }
  
  // Bind field validation cleanup (remove highlight when user starts typing)
  bindFieldValidationCleanup();
  
  // Bind scroll behavior for comments to materials transition
  bindCommentsToMaterialsScroll();
  
  // Bind dimension and quantity change events for recalculation
  bindDimensionChangeEvents();
  
  // Bind section collapse/expand functionality
  bindSectionCollapseEvents();
  
  // Bind sidebar navigation functionality
  bindSectionNavigationEvents();
  
  // Bind global process addition
  const addGlobalProcessBtn = document.getElementById('add-global-process-btn');
  if (addGlobalProcessBtn) {
    addGlobalProcessBtn.addEventListener('click', addGlobalProcess);
  }
  
  // Bind manual global process addition
  const addManualGlobalProcessBtn = document.getElementById('add-manual-global-process-btn');
  if (addManualGlobalProcessBtn) {
    addManualGlobalProcessBtn.addEventListener('click', addManualGlobalProcess);
  }
  
  // Bind extra addition
  const addExtraBtn = document.getElementById('add-extra-btn');
  if (addExtraBtn) {
    addExtraBtn.addEventListener('click', addExtra);
  }
  
  // Bind manual extra addition
  const addManualExtraBtn = document.getElementById('add-manual-extra-btn');
  if (addManualExtraBtn) {
    addManualExtraBtn.addEventListener('click', addManualExtra);
  }
}

function loadMaterials() {
  
  // Clear any existing options first
  const materialSelect = document.getElementById('material-select');
  if (materialSelect) {
    materialSelect.innerHTML = '<option value="">Selecciona un material precargado</option>';
  }
  
  // Load from API
  fetch('/api/v1/materials', {
    method: 'GET',
    credentials: 'same-origin',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(materials => {
    if (materials && materials.length > 0) {
      populateMaterialSelect(materials);
      formState.availableMaterials = materials;
    }
  })
  .catch(error => {
    console.error('❌ Error loading materials:', error);
    console.error('Error details:', error.message);
    showValidationMessage('Error al cargar materiales. Por favor recarga la página.');
  });
}

function loadManufacturingProcesses() {
  
  fetch('/api/v1/manufacturing_processes', {
    method: 'GET',
    credentials: 'same-origin',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(processes => {
    formState.availableProcesses = processes;
    populateGlobalProcessSelect(processes);
  })
  .catch(error => {
    console.error('❌ Error loading manufacturing processes:', error);
    showValidationMessage('Error al cargar procesos. Por favor recarga la página.');
  });
}

function loadExtras() {
  
  fetch('/api/v1/indirect_costs', {
    method: 'GET',
    credentials: 'same-origin',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(extras => {
    formState.availableExtras = extras;
    populateExtraSelect(extras);
  })
  .catch(error => {
    console.error('❌ Error loading extras:', error);
    showValidationMessage('Error al cargar extras. Por favor recarga la página.');
  });
}

function loadUnits() {
  
  fetch('/api/v1/units', {
    method: 'GET',
    credentials: 'same-origin',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(units => {
    formState.availableUnits = units;
    console.log('✅ Units loaded:', units.length);
  })
  .catch(error => {
    console.error('❌ Error loading units:', error);
    showValidationMessage('Error al cargar unidades. Por favor recarga la página.');
  });
}

function populateMaterialSelect(materials) {
  const materialSelect = document.getElementById('material-select');
  if (!materialSelect) {
    console.error('❌ Material select element not found!');
    return;
  }
  
  // Clear existing options except the first one
  materialSelect.innerHTML = '<option value="">Selecciona un material precargado</option>';
  
  // Add materials to dropdown
  materials.forEach((material, index) => {
    const option = document.createElement('option');
    option.value = material.id;
    option.textContent = `${material.description} (${material.unit})`;
    option.dataset.material = JSON.stringify(material);
    materialSelect.appendChild(option);
  });
}

// Bind scroll behavior for comments to materials transition
function bindCommentsToMaterialsScroll() {
  const commentsField = document.querySelector('[name="comments"]');
  const materialSelect = document.getElementById('material-select');
  const materialsSection = document.getElementById('section-2');
  
  if (!commentsField || !materialSelect || !materialsSection) {
    console.warn('⚠️ Could not bind comments to materials scroll - missing elements');
    console.log('Comments field:', commentsField);
    console.log('Material select:', materialSelect);
    console.log('Materials section:', materialsSection);
    return;
  }
  
  let isTabPressed = false;
  let lastFocusedElement = null;
  
  // Track Tab key press
  document.addEventListener('keydown', function(event) {
    if (event.key === 'Tab') {
      isTabPressed = true;
      lastFocusedElement = document.activeElement;
    }
  });
  
  // Track focus changes
  document.addEventListener('focusin', function(event) {
    // If Tab was pressed and we're now focusing on material select
    if (isTabPressed && event.target === materialSelect && lastFocusedElement === commentsField) {
      console.log('🎯 TAB detected from comments to material select - triggering scroll');
      
      // Scroll to materials section with proper offset to show the full header
      setTimeout(() => {
        const rect = materialsSection.getBoundingClientRect();
        
        // Calculate the scroll position to show the complete materials section
        // We want to show the section header and content, not just the top edge
        const scrollTop = window.pageYOffset + rect.top - 40; // Reduced offset to show more content
        
        console.log('📊 Pre-scroll state:', {
          materialsSectionTop: rect.top,
          scrollTop: scrollTop,
          currentScrollY: window.pageYOffset,
          windowHeight: window.innerHeight,
          documentHeight: document.documentElement.scrollHeight
        });
        
        // Use window.scrollTo with calculated position for precise control
        try {
          setTimeout(() => {
            const rect = materialsSection.getBoundingClientRect();
            const scrollTop = window.pageYOffset + rect.top - 50; // 50px offset to show header
            
            window.scrollTo({
              top: scrollTop,
              behavior: 'smooth'
            });
            
            console.log('📜 window.scrollTo applied with calculated position:', {
              materialsSectionTop: rect.top,
              scrollTop: scrollTop,
              offset: -50
            });
          }, 200);
          
        } catch (error) {
          console.error('❌ Scroll error:', error);
        }
        
        // Verify scroll worked after a delay
        setTimeout(() => {
          console.log('📊 Post-scroll state:', {
            newScrollY: window.pageYOffset,
            materialsSectionTop: materialsSection.getBoundingClientRect().top
          });
        }, 500);
        
      }, 100); // Slightly longer delay to ensure focus is complete
    }
    
    // Reset Tab flag after focus change
    isTabPressed = false;
    lastFocusedElement = null;
  });
  
  console.log('✅ Comments to materials scroll behavior bound');
}

// Función para limpiar destacados cuando el usuario empieza a escribir
function bindFieldValidationCleanup() {
  
  const requiredFields = [
    // '[name="product[description]"]', // Descripción NO es obligatoria
    '[name="product[quantity]"]', 
    '[name="width"]',
    '[name="length"]'
  ];
  
  requiredFields.forEach(selector => {
    const field = document.querySelector(selector);
    if (field) {
      field.addEventListener('input', function() {
        // Limpiar highlight de este campo específico cuando el usuario escriba
        this.classList.remove('is-invalid');
        this.style.borderColor = '';
        this.style.boxShadow = '';
      });
    }
  });
}

// Bind dimension and quantity change events for recalculation
function bindDimensionChangeEvents() {
  
  const fields = [
    '[name="product[quantity]"]',
    '[name="width"]',
    '[name="length"]'
  ];
  
  fields.forEach(selector => {
    const field = document.querySelector(selector);
    if (field) {
      field.addEventListener('input', handleDimensionChange);
      field.addEventListener('change', handleDimensionChange);
    } else {
      console.warn(`⚠️ Field not found: ${selector}`);
    }
  });
}

// Bind section collapse/expand functionality
function bindSectionCollapseEvents() {
  
  const sectionHeaders = document.querySelectorAll('.section-header');
  
  sectionHeaders.forEach(header => {
    header.addEventListener('click', toggleSectionCollapse);
  });
}

// Toggle section collapse/expand
function toggleSectionCollapse(event) {
  const header = event.currentTarget;
  const section = header.closest('.form-section');
  const content = section.querySelector('.section-content');
  
  if (!section || !content) {
    console.warn('⚠️ Section or content not found');
    return;
  }
  
  // Toggle collapsed class
  section.classList.toggle('collapsed');
  
  // Update collapse indicator
  const collapseIndicator = header.querySelector('.collapse-indicator');
  if (collapseIndicator) {
    collapseIndicator.classList.toggle('collapsed');
  }
  
  // Update content visibility
  if (section.classList.contains('collapsed')) {
    content.style.maxHeight = '0';
    content.style.padding = '0 30px';
    console.log('📁 Section collapsed');
  } else {
    content.style.maxHeight = '2000px';
    content.style.padding = '25px 30px';
    console.log('📂 Section expanded');
  }
}

// Bind section navigation events (sidebar only)
function bindSectionNavigationEvents() {
  
  // Bind sidebar navigation
  const sidebarSteps = document.querySelectorAll('.step-item');
  sidebarSteps.forEach(step => {
    step.addEventListener('click', navigateToSection);
  });
}

// Navigate to specific section from sidebar
function navigateToSection(event) {
  event.preventDefault();
  
  const stepItem = event.currentTarget;
  const targetStep = parseInt(stepItem.dataset.step);
  
  if (targetStep && targetStep >= 1 && targetStep <= formState.totalSteps) {
    navigateToStep(targetStep);
  }
}

// Navigate to specific step
function navigateToStep(stepNumber) {
  console.log(`🔄 Navigating to step ${stepNumber}`);
  
  // Validate current section before moving
  if (!validateCurrentSection()) {
    console.log('❌ Current section validation failed');
    return;
  }
  
  // Update current step
  formState.currentStep = stepNumber;
  
  // Update progress indicator
  updateProgressIndicator();
  
  // Scroll to the target section
  const targetSection = document.getElementById(`section-${stepNumber}`);
  if (targetSection) {
    targetSection.scrollIntoView({ 
      behavior: 'smooth', 
      block: 'start' 
    });
    
    // Expand the target section if it's collapsed
    if (targetSection.classList.contains('collapsed')) {
      const header = targetSection.querySelector('.section-header');
      const content = targetSection.querySelector('.section-content');
      const collapseIndicator = header.querySelector('.collapse-indicator');
      
      targetSection.classList.remove('collapsed');
      if (collapseIndicator) {
        collapseIndicator.classList.remove('collapsed');
      }
      content.style.maxHeight = '2000px';
      content.style.padding = '25px 30px';
    }
    
    console.log(`✅ Navigated to step ${stepNumber}`);
  } else {
    console.error(`❌ Target section not found: section-${stepNumber}`);
  }
}

// Validate current section before navigation
function validateCurrentSection() {
  const currentSection = document.getElementById(`section-${formState.currentStep}`);
  if (!currentSection) return true;
  
  // Section-specific validation
  switch (formState.currentStep) {
    case 1: // General Info
      return validateGeneralInfoSection();
    case 2: // Materials
      return validateMaterialsSection();
    case 3: // Global Processes
      return true; // Optional section
    case 4: // Extras
      return true; // Optional section
    case 5: // Final Calculation
      return true; // Read-only section
    default:
      return true;
  }
}

// Validate General Info section
function validateGeneralInfoSection() {
  const quantity = document.querySelector('[name="product[quantity]"]')?.value?.trim();
  const width = document.querySelector('[name="width"]')?.value?.trim();
  const length = document.querySelector('[name="length"]')?.value?.trim();
  
  if (!quantity || quantity === '0' || parseFloat(quantity) <= 0) {
    showValidationMessage('Por favor ingresa una cantidad válida de piezas.');
    highlightField('[name="product[quantity]"]');
    return false;
  }
  
  if (!width || width === '0' || parseFloat(width) <= 0) {
    showValidationMessage('Por favor ingresa un ancho válido.');
    highlightField('[name="width"]');
    return false;
  }
  
  if (!length || length === '0' || parseFloat(length) <= 0) {
    showValidationMessage('Por favor ingresa un alto válido.');
    highlightField('[name="length"]');
    return false;
  }
  
  return true;
}

// Validate Materials section
function validateMaterialsSection() {
  const materialCards = document.querySelectorAll('.material-card[data-material-id]');
  
  if (materialCards.length === 0) {
    showValidationMessage('Por favor agrega al menos un material antes de continuar.');
    return false;
  }
  
  return true;
}

// Handle dimension changes and trigger recalculation
function handleDimensionChange(event) {
  // Small delay to ensure the value is updated
  setTimeout(() => {
    recalculateAllMaterials();
    recalculateAllProcesses();
    recalculateAllGlobalProcesses();
    triggerRecalculation();
  }, 100);
}

// Recalculate all materials when dimensions change
function recalculateAllMaterials() {
  
  const materialCards = document.querySelectorAll('.material-card[data-material-id]');
  
  materialCards.forEach(card => {
    const materialId = card.dataset.materialId;
    const originalMaterial = formState.availableMaterials.find(m => m.id == materialId);
    
    if (originalMaterial) {
      // Get current product dimensions
      const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
      const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
      const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
      
      // Get edited material data
      const materialData = formState.productData.materials?.[materialId] || {};
      
      // Update material fields with new product dimensions
      const anchoField = card.querySelector('[data-field="ancho"]');
      const largoField = card.querySelector('[data-field="largo"]');
      
      if (anchoField) {
        const currentValue = parseFloat(anchoField.value) || 0;
        if (currentValue !== productWidth) {
          anchoField.value = productWidth;
          // Update the stored data
          if (!formState.productData.materials[materialId]) {
            formState.productData.materials[materialId] = {};
          }
          formState.productData.materials[materialId].ancho = productWidth;
          console.log(`📏 Updated material ${materialId} ancho: ${currentValue} → ${productWidth}`);
        }
      }
      
      if (largoField) {
        const currentValue = parseFloat(largoField.value) || 0;
        if (currentValue !== productLength) {
          largoField.value = productLength;
          // Update the stored data
          if (!formState.productData.materials[materialId]) {
            formState.productData.materials[materialId] = {};
          }
          formState.productData.materials[materialId].largo = productLength;
          console.log(`📏 Updated material ${materialId} largo: ${currentValue} → ${productLength}`);
        }
      }
      
      // Create updated material object with new dimensions and preserved cost/pieces
      const updatedMaterial = {
        ...originalMaterial,
        ancho: productWidth,
        largo: productLength,
        cost: materialData.cost || originalMaterial.cost || originalMaterial.price,
        price: materialData.cost || originalMaterial.cost || originalMaterial.price
      };
      
      // Recalculate material data
      const calculatedData = calculateMaterialData(updatedMaterial, productQuantity, productWidth, productLength);
      
      // Update pieces if it was manually edited
      if (materialData.pieces) {
        calculatedData.piecesPerMaterial = materialData.pieces;
      }
      
      // Update material card display (preserve editable fields when recalculating from dimension changes)
      updateMaterialCardDisplay(card, calculatedData, true);
    }
  });
}

// Recalculate all material processes when dimensions change
function recalculateAllProcesses() {
  
  const processRows = document.querySelectorAll('.process-row');
  
  processRows.forEach(row => {
    const materialId = row.dataset.materialId;
    const processId = row.dataset.processId;
    
    // Get the process data from the row
    const processDescription = row.querySelector('.col-md-3 strong')?.textContent;
    const processUnit = row.querySelector('.col-md-1:nth-child(2) strong')?.textContent;
    const processPrice = row.querySelector('.col-md-1:nth-child(4) strong')?.textContent;
    
    if (processDescription && processUnit && processPrice) {
      // Create process object for calculation
      const process = {
        id: processId,
        description: processDescription,
        unit: processUnit,
        price: parseFloat(processPrice.replace(/[$,]/g, '')) || 0
      };
      
      // Get current product dimensions
      const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
      const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
      const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
      
      // Get material data for this process
      const materialData = getMaterialCalculatedData(materialId, productQuantity, productWidth, productLength);
      
      // Recalculate process data
      const calculatedProcessData = calculateProcessData(process, materialData, productQuantity, productWidth, productLength);
      
      // Update process row display
      updateProcessRowDisplay(row, calculatedProcessData, productQuantity);
    }
  });
}

// Update process row display with new calculated data
function updateProcessRowDisplay(row, calculatedProcessData, productQuantity) {
  // Update editable fields (only if not focused to avoid interrupting user input)
  const timesField = row.querySelector('[data-field="times"]');
  if (timesField && timesField !== document.activeElement) {
    timesField.value = calculatedProcessData.times || 1;
  }
  
  const costField = row.querySelector('[data-field="cost"]');
  if (costField && costField !== document.activeElement) {
    costField.value = calculatedProcessData.price || calculatedProcessData.cost || calculatedProcessData.basePrice || 0;
  }
  
  const sideField = row.querySelector('[data-field="side"]');
  if (sideField && sideField !== document.activeElement) {
    sideField.value = calculatedProcessData.side || 'front';
  }
  
  // Only update the total cost field
  
  const totalCostElement = row.querySelector('.total-cost');
  if (totalCostElement) {
    totalCostElement.textContent = formatCurrency(calculatedProcessData.totalPrice);
  }
}

// Recalculate all global processes when dimensions change
function recalculateAllGlobalProcesses() {
  
  const globalProcessCards = document.querySelectorAll('.material-card[data-process-id]');
  
  globalProcessCards.forEach(card => {
    const processId = card.dataset.processId;
    const side = card.dataset.side;
    
    // Get the process data from the card
    const processDescription = card.querySelector('.col-md-4 strong')?.textContent;
    const processUnit = card.querySelector('.col-md-1:nth-child(2) strong')?.textContent;
    const processPrice = card.querySelector('.col-md-1:nth-child(4) strong')?.textContent;
    
    if (processDescription && processUnit && processPrice) {
      // Create process object for calculation
      const process = {
        id: processId,
        description: processDescription,
        unit: processUnit,
        price: parseFloat(processPrice.replace(/[$,]/g, '')) || 0
      };
      
      // Get current product dimensions
      const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
      const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
      const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
      
      // Recalculate global process data
      const calculatedProcessData = calculateGlobalProcessData(process, productQuantity, productWidth, productLength, side);
      
      // Update global process card display
      updateGlobalProcessCardDisplay(card, calculatedProcessData, productQuantity);
    }
  });
}

// Update global process card display with new calculated data
function updateGlobalProcessCardDisplay(card, calculatedProcessData, productQuantity) {
  // Update pieces
  const piecesElement = card.querySelector('.col-md-1:nth-child(7) strong');
  if (piecesElement) {
    piecesElement.textContent = productQuantity;
  }
  
  // Update total cost
  const totalCostElement = card.querySelector('.total-cost');
  if (totalCostElement) {
    totalCostElement.textContent = formatCurrency(calculatedProcessData.totalPrice);
  }
}

// Validación de campos requeridos antes de agregar materiales
function validateRequiredFields() {
  console.log('🔍 Validating required fields...');
  
  // Obtener los valores de los campos requeridos (nombres exactos del HTML)
  const description = document.querySelector('[name="product[description]"]')?.value?.trim();
  const quantity = document.querySelector('[name="product[quantity]"]')?.value?.trim();
  const width = document.querySelector('[name="width"]')?.value?.trim();
  const length = document.querySelector('[name="length"]')?.value?.trim(); // "Alto" en el HTML
  
  console.log('📋 Field values:', { description, quantity, width, length });
  
  // Verificar que todos los campos requeridos estén completos
  const missingFields = [];
  
  // Descripción NO es obligatoria para agregar materiales
  // if (!description) {
  //   missingFields.push('Descripción del producto');
  // }
  
  if (!quantity || quantity === '0' || parseFloat(quantity) <= 0) {
    missingFields.push('Cantidad de piezas');
  }
  
  if (!width || width === '0' || parseFloat(width) <= 0) {
    missingFields.push('Ancho');
  }
  
  if (!length || length === '0' || parseFloat(length) <= 0) {
    missingFields.push('Alto');
  }
  
  if (missingFields.length > 0) {
    // Marcar campos faltantes visualmente
    highlightMissingFields({ description, quantity, width, length });
    
    const message = `Para agregar materiales, primero completa: ${missingFields.join(', ')}`;
    console.log('❌ Validation failed:', message);
    return {
      isValid: false,
      message: message
    };
  }
  
  // Limpiar cualquier destacado de error previo
  clearFieldHighlights();
  
  console.log('✅ All required fields are valid');
  return {
    isValid: true,
    message: 'Campos válidos'
  };
}

// Función para destacar campos faltantes
function highlightMissingFields(fieldValues) {
  console.log('🔴 Highlighting missing fields...');
  
  // Limpiar highlights previos
  clearFieldHighlights();
  
  // Destacar cada campo faltante (descripción NO es obligatoria)
  // if (!fieldValues.description) {
  //   highlightField('[name="product[description]"]');
  // }
  
  if (!fieldValues.quantity || fieldValues.quantity === '0' || parseFloat(fieldValues.quantity) <= 0) {
    highlightField('[name="product[quantity]"]');
  }
  
  if (!fieldValues.width || fieldValues.width === '0' || parseFloat(fieldValues.width) <= 0) {
    highlightField('[name="width"]');
  }
  
  if (!fieldValues.length || fieldValues.length === '0' || parseFloat(fieldValues.length) <= 0) {
    highlightField('[name="length"]');
  }
}

// Función para destacar un campo específico
function highlightField(selector) {
  const field = document.querySelector(selector);
  if (field) {
    field.classList.add('is-invalid');
    field.style.borderColor = '#e74c3c';
    field.style.boxShadow = '0 0 0 0.2rem rgba(231, 76, 60, 0.25)';
  }
}

// Función para limpiar destacados
function clearFieldHighlights() {
  const highlightedFields = document.querySelectorAll('.is-invalid, [style*="border-color"]');
  highlightedFields.forEach(field => {
    field.classList.remove('is-invalid');
    field.style.borderColor = '';
    field.style.boxShadow = '';
  });
}

function addMaterialWithProcesses() {
  console.log('➕ Adding material with processes...');
  
  // VALIDACIÓN: Verificar que los campos básicos estén completos
  const validation = validateRequiredFields();
  if (!validation.isValid) {
    showValidationMessage(validation.message);
    return;
  }
  
  const materialSelect = document.getElementById('material-select');
  const selectedOption = materialSelect.options[materialSelect.selectedIndex];
  
  if (!selectedOption.value) {
    showValidationMessage('Por favor selecciona un material.');
    return;
  }
  
  // Validate that the selected option has material data
  if (!selectedOption.dataset.material) {
    showValidationMessage('La opción seleccionada no contiene datos de material válidos. Por favor selecciona un material de la lista.');
    return;
  }
  
  // Get material data
  let materialData;
  try {
    materialData = JSON.parse(selectedOption.dataset.material);
  } catch (error) {
    console.error('❌ Error parsing material data:', error);
    showValidationMessage('Error al procesar los datos del material. Por favor intenta nuevamente.');
    return;
  }
  
  console.log('📦 Adding material:', materialData);
  
  // Add to formState
  formState.productData.materials_with_processes.push(materialData);
  console.log('💾 Material added to formState:', formState.productData.materials_with_processes);
  
  // Create material card with processes
  const materialCard = createMaterialCard(materialData);
  
  // Add to DOM
  const materialsList = document.getElementById('materials-with-processes-list');
  if (materialsList) {
    materialsList.insertAdjacentHTML('beforeend', materialCard);
    
    // Bind events for the new card
    const newCard = materialsList.lastElementChild;
    bindMaterialCardEvents(newCard);
    
    // Reset selector
    materialSelect.selectedIndex = 0;
    
    console.log('✅ Material card added and events bound');
    showValidationMessage('Material agregado correctamente', 'success');
    
    // Trigger recalculation
    triggerRecalculation();
  } else {
    console.error('❌ Materials list container not found');
  }
}

function addManualMaterial() {
  console.log('➕ Adding manual material...');
  
  // VALIDACIÓN: Verificar que los campos básicos estén completos
  const validation = validateRequiredFields();
  if (!validation.isValid) {
    showValidationMessage(validation.message);
    return;
  }
  
  // Create a new manual material with default values
  const manualMaterial = {
    id: 'manual_' + Date.now(), // Unique ID for manual materials
    description: 'Material nuevo',
    unit: 'm2',
    ancho: 0,
    largo: 0,
    cost: 0,
    weight: null,
    manual: true
  };
  
  console.log('📦 Creating manual material:', manualMaterial);
  
  // Add to formState
  formState.productData.materials_with_processes.push(manualMaterial);
  console.log('💾 Manual material added to formState:', formState.productData.materials_with_processes);
  
  // Create material card with processes
  const materialCard = createManualMaterialCard(manualMaterial);
  
  // Add to DOM
  const materialsList = document.getElementById('materials-with-processes-list');
  if (materialsList) {
    materialsList.insertAdjacentHTML('beforeend', materialCard);
    
    // Bind events for the new card
    const newCard = materialsList.lastElementChild;
    bindMaterialCardEvents(newCard);
    
    // Focus on the description field for better UX
    const descriptionField = newCard.querySelector('input[data-field="description"]');
    if (descriptionField) {
      descriptionField.focus();
      descriptionField.select(); // Select the default text so user can type immediately
    }
    
    console.log('✅ Manual material card added and events bound');
    showValidationMessage('Material manual agregado correctamente', 'success');
    
    // Trigger recalculation
    triggerRecalculation();
  } else {
    console.error('❌ Materials list container not found');
  }
}

function createManualMaterialCard(material) {
  console.log('🏗️ Creating manual material card for:', material.description);
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Calculate material data
  const calculatedData = calculateMaterialData(material, productQuantity, productWidth, productLength);
  
  return `
    <div class="material-card" data-material-id="${material.id}">
      <div class="material-info">
        <div class="material-details">
          <div class="row">
            <div class="col-md-3">
              <small class="text-muted">Material:</small><br>
              <input type="text" class="form-control form-control-sm material-field" 
                     data-field="description" data-material-id="${material.id}" 
                     value="${material.description}" 
                     style="width: 100%; display: inline-block; text-align: left;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Ancho</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="ancho" data-material-id="${material.id}" 
                     value="${material.ancho || 0}" min="0" step="0.1" 
                     style="width: 80px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Largo</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="largo" data-material-id="${material.id}" 
                     value="${material.largo || 0}" min="0" step="0.1" 
                     style="width: 80px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Costo</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="cost" data-material-id="${material.id}" 
                     value="${material.cost || 0}" min="0" step="0.01" 
                     style="width: 90px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Piezas</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="pieces" data-material-id="${material.id}" 
                     value="${calculatedData.piecesPerMaterial}" min="1" step="1" 
                     style="width: 70px; display: inline-block;">
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Pliegos</small><br>
              <strong class="calculated-value" data-field="sheets">${calculatedData.totalSheets}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Peso</small><br>
              <strong class="calculated-value" data-field="weight">${calculatedData.totalWeight}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">m²</small><br>
              <strong class="calculated-value" data-field="squareMeters">${calculatedData.isWeightBased ? '-' : calculatedData.totalSquareMeters}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Costo total</small><br>
              <strong class="calculated-value material-total-cost" data-field="totalCost">${formatCurrency(calculatedData.totalPrice)}</strong>
            </div>
            <div class="col-md-1 d-flex justify-content-end align-items-center">
              <small class="text-muted">&nbsp;</small><br>
              <button type="button" class="btn btn-sm btn-outline-danger remove-material-btn" data-material-id="${material.id}">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>
        <!-- Hidden quantity field with default value 1 -->
        <input type="hidden" class="material-quantity" value="1" data-material-id="${material.id}">
      </div>
      <div class="material-processes">
        <h6>Procesos para este material:</h6>
        <div class="processes-selection">
          <div class="row">
            <div class="col-md-6">
              <select class="form-select process-selector" data-material-id="${material.id}">
                <option value="">Selecciona un proceso...</option>
                ${createProcessOptions(material)}
              </select>
            </div>
            <div class="col-md-6 d-flex gap-3 justify-content-end">
              <button type="button" class="btn btn-success add-process-btn" data-material-id="${material.id}">
                <i class="fas fa-plus me-1"></i> Agregar seleccionado
              </button>
              <button type="button" class="btn btn-outline-success add-manual-process-btn" data-material-id="${material.id}">
                <i class="fas fa-plus me-1"></i> Agregar nuevo
              </button>
            </div>
          </div>
          <div class="selected-processes mt-3" data-material-id="${material.id}">
            <!-- Selected processes will appear here -->
          </div>
        </div>
      </div>
    </div>
  `;
}

function createMaterialCard(material) {
  console.log('🏗️ Creating material card for:', material.description);
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Calculate material data
  const calculatedData = calculateMaterialData(material, productQuantity, productWidth, productLength);
  
  return `
    <div class="material-card" data-material-id="${material.id}">
      <div class="material-info">
        <div class="material-details">
          <div class="row">
            <div class="col-md-3">
              <small class="text-muted">Material:</small><br>
              <strong>${material.description}</strong>
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Ancho</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="ancho" data-material-id="${material.id}" 
                     value="${material.ancho || 0}" min="0" step="0.1" 
                     style="width: 80px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Largo</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="largo" data-material-id="${material.id}" 
                     value="${material.largo || 0}" min="0" step="0.1" 
                     style="width: 80px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Costo</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="cost" data-material-id="${material.id}" 
                     value="${material.cost || material.price || 0}" min="0" step="0.01" 
                     style="width: 90px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Piezas</small><br>
              <input type="number" class="form-control form-control-sm material-field" 
                     data-field="pieces" data-material-id="${material.id}" 
                     value="${calculatedData.piecesPerMaterial}" min="1" step="1" 
                     style="width: 70px; display: inline-block;">
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Pliegos</small><br>
              <strong class="calculated-value" data-field="sheets">${calculatedData.totalSheets}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Peso</small><br>
              <strong class="calculated-value" data-field="weight">${calculatedData.totalWeight}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">m²</small><br>
              <strong class="calculated-value" data-field="squareMeters">${calculatedData.isWeightBased ? '-' : calculatedData.totalSquareMeters}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Costo total</small><br>
              <strong class="calculated-value material-total-cost" data-field="totalCost">${formatCurrency(calculatedData.totalPrice)}</strong>
            </div>
            <div class="col-md-1 d-flex justify-content-end align-items-center">
              <small class="text-muted">&nbsp;</small><br>
              <button type="button" class="btn btn-sm btn-outline-danger remove-material-btn" data-material-id="${material.id}">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>
        <!-- Hidden quantity field with default value 1 -->
        <input type="hidden" class="material-quantity" value="1" data-material-id="${material.id}">
      </div>
      <div class="material-processes">
        <h6>Procesos para este material:</h6>
        <div class="processes-selection">
          <div class="row">
            <div class="col-md-6">
              <select class="form-select process-selector" data-material-id="${material.id}">
                <option value="">Selecciona un proceso...</option>
                ${createProcessOptions(material)}
              </select>
            </div>
            <div class="col-md-6 d-flex gap-3 justify-content-end">
              <button type="button" class="btn btn-success add-process-btn" data-material-id="${material.id}">
                <i class="fas fa-plus me-1"></i> Agregar seleccionado
              </button>
              <button type="button" class="btn btn-outline-success add-manual-process-btn" data-material-id="${material.id}">
                <i class="fas fa-plus me-1"></i> Agregar nuevo
              </button>
            </div>
          </div>
          <div class="selected-processes mt-3" data-material-id="${material.id}">
            <!-- Selected processes will appear here -->
          </div>
        </div>
      </div>
    </div>
  `;
}

function createProcessOptions(material) {
  console.log('⚙️ Creating process options for material:', material.id);
  
  if (!formState.availableProcesses || formState.availableProcesses.length === 0) {
    return '<option value="">Cargando procesos...</option>';
  }
  
  return formState.availableProcesses.map(process => `
    <option value="${process.id}" data-process='${JSON.stringify(process)}'>
      ${process.description}
    </option>
  `).join('');
}

function bindMaterialCardEvents(card) {
  console.log('🔗 Binding events for material card...');
  
  // Bind editable material fields
  const materialFields = card.querySelectorAll('.material-field');
  materialFields.forEach(field => {
    field.addEventListener('input', handleMaterialFieldChange);
    field.addEventListener('change', handleMaterialFieldChange);
    console.log('✅ Material field bound:', field.dataset.field, 'for material', field.dataset.materialId);
  });
  
  // Bind editable process fields
  const processFields = card.querySelectorAll('.process-field');
  processFields.forEach(field => {
    field.addEventListener('input', handleProcessFieldChange);
    field.addEventListener('change', handleProcessFieldChange);
    
    // For select fields, also listen to change events more explicitly
    if (field.tagName === 'SELECT') {
      field.addEventListener('change', function(event) {
        console.log('🔄 Select field changed:', event.target.dataset.field, 'to:', event.target.value);
        handleProcessFieldChange(event);
      });
    }
    
    console.log('✅ Process field bound:', field.dataset.field, 'for process', field.dataset.processId);
  });
  
  // Add process button
  const addProcessBtn = card.querySelector('.add-process-btn');
  if (addProcessBtn) {
    addProcessBtn.addEventListener('click', addProcessToMaterial);
  }
  
  // Add manual process button
  const addManualProcessBtn = card.querySelector('.add-manual-process-btn');
  if (addManualProcessBtn) {
    addManualProcessBtn.addEventListener('click', addManualProcessToMaterial);
  }
  
  // Remove material
  const removeButton = card.querySelector('.remove-material-btn');
  if (removeButton) {
    removeButton.addEventListener('click', removeMaterial);
  }
  
  console.log('✅ Material card events bound');
}

// Handle material field changes
function handleMaterialFieldChange(event) {
  const field = event.target;
  const materialId = field.dataset.materialId;
  const fieldName = field.dataset.field;
  const newValue = fieldName === 'description' ? field.value : (parseFloat(field.value) || 0);
  
  console.log(`📝 Material field changed: ${fieldName} = ${newValue} for material ${materialId}`);
  
  // Update the material data in formState
  updateMaterialData(materialId, fieldName, newValue);
  
  // Update the material in the materials_with_processes array
  const materialIndex = formState.productData.materials_with_processes.findIndex(m => m.id == materialId);
  if (materialIndex !== -1) {
    formState.productData.materials_with_processes[materialIndex][fieldName] = newValue;
    console.log(`💾 Updated material ${materialId} ${fieldName} in materials_with_processes:`, newValue);
  } else {
    console.warn(`⚠️ Material ${materialId} not found in materials_with_processes when updating ${fieldName}`);
    console.log('📋 Available materials in materials_with_processes:', formState.productData.materials_with_processes.map(m => ({ id: m.id, description: m.description })));
  }
  
  // Recalculate this material's values
  console.log(`🔄 About to recalculate material ${materialId}`);
  recalculateSingleMaterial(materialId);
  console.log(`✅ Finished recalculating material ${materialId}`);
  
  // Recalculate all processes for this material when material dimensions change
  setTimeout(() => {
    recalculateAllProcessesForMaterial(materialId);
  }, 50);
  
  // Trigger overall recalculation
  setTimeout(() => {
    triggerRecalculation();
  }, 100);
}

// Recalculate all processes for a specific material
function recalculateAllProcessesForMaterial(materialId) {
  console.log(`🔄 Recalculating all processes for material ${materialId}`);
  
  // Find all process rows for this material
  const processRows = document.querySelectorAll(`.process-row[data-material-id="${materialId}"]`);
  
  processRows.forEach(row => {
    const processId = row.dataset.processId;
    console.log(`🔄 Recalculating process ${processId} for material ${materialId}`);
    recalculateSingleProcess(materialId, processId);
  });
  
  console.log(`✅ Finished recalculating ${processRows.length} processes for material ${materialId}`);
}

// Handle process field changes
function handleProcessFieldChange(event) {
  const field = event.target;
  const processId = field.dataset.processId;
  const materialId = field.dataset.materialId;
  const fieldName = field.dataset.field;
  
  let newValue;
  if (fieldName === 'unit' && field.tagName === 'SELECT') {
    // Handle unit selection - get the unit name from the selected option
    const selectedOption = field.options[field.selectedIndex];
    if (selectedOption && selectedOption.dataset.unitName) {
      newValue = selectedOption.dataset.unitName;
    } else {
      newValue = field.value;
    }
  } else {
    newValue = field.type === 'number' ? parseFloat(field.value) || 0 : field.value;
  }
  
  console.log(`📝 Process field changed: ${fieldName} = ${newValue} for process ${processId} in material ${materialId}`);
  
  // Update the process data in formState
  // Map 'cost' field to 'price' in formState for consistency
  const stateFieldName = fieldName === 'cost' ? 'price' : fieldName;
  updateProcessData(materialId, processId, stateFieldName, newValue);
  
  // Recalculate this process's values
  console.log(`🔄 Recalculating process ${processId} for material ${materialId}`);
  recalculateSingleProcess(materialId, processId);
  
  // Trigger overall recalculation
  setTimeout(() => {
    console.log(`🔄 Triggering overall recalculation after process change`);
    triggerRecalculation();
  }, 100);
}

// Update material data in formState
function updateMaterialData(materialId, fieldName, value) {
  if (!formState.productData.materials) {
    formState.productData.materials = {};
  }
  
  if (!formState.productData.materials[materialId]) {
    formState.productData.materials[materialId] = {};
  }
  
  formState.productData.materials[materialId][fieldName] = value;
}

// Update process data in formState
function updateProcessData(materialId, processId, fieldName, value) {
  if (!formState.productData.processes) {
    formState.productData.processes = {};
  }
  
  if (!formState.productData.processes[materialId]) {
    formState.productData.processes[materialId] = {};
  }
  
  if (!formState.productData.processes[materialId][processId]) {
    formState.productData.processes[materialId][processId] = {};
  }
  
  formState.productData.processes[materialId][processId][fieldName] = value;
}

// Recalculate single process
function recalculateSingleProcess(materialId, processId) {
  const processRow = document.querySelector(`[data-process-id="${processId}"][data-material-id="${materialId}"]`);
  if (!processRow) {
    console.warn(`⚠️ Process row not found for process ${processId} in material ${materialId}`);
    return;
  }
  
  // Get current process data
  const processData = formState.productData.processes?.[materialId]?.[processId] || {};
  let originalProcess = formState.availableProcesses.find(p => p.id == processId);
  
  // If not found in available processes, it might be a manual process
  if (!originalProcess) {
    console.log(`📝 Process ${processId} not found in available processes, treating as manual process`);
    // Create a base manual process object
    originalProcess = {
      id: processId,
      description: processData.description || 'Proceso manual',
      price: processData.price || 0,
      unit: processData.unit || 'pieza',
      manual: true
    };
  }
  
  console.log(`📊 Process data for recalculation:`, processData);
  
  // Get material data for calculations
  const materialCard = document.querySelector(`[data-material-id="${materialId}"]`);
  const originalMaterial = formState.availableMaterials.find(m => m.id == materialId);
  
  if (!originalMaterial) {
    console.warn(`⚠️ Original material not found for material ${materialId}`);
    return;
  }
  
  // Get current product dimensions
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Get material data with all calculated values
  const materialData = getMaterialCalculatedData(materialId, productQuantity, productWidth, productLength);
  
  console.log(`📊 Material data for process calculation:`, materialData);
  
  // Merge original process with user edits
  const updatedProcess = {
    ...originalProcess,
    ...processData
  };
  
  // Use the calculated material data (which includes user edits)
  const updatedMaterial = materialData;
  
  console.log(`🔄 Updated process for calculation:`, updatedProcess);
  
  // Calculate process data with updated values
  const calculatedProcessData = calculateProcessData(updatedProcess, updatedMaterial, productQuantity, productWidth, productLength);
  
  console.log(`💰 Calculated process data:`, calculatedProcessData);
  
  // Update process row display
  updateProcessRowDisplay(processRow, calculatedProcessData, productQuantity);
}

// Recalculate single material
function recalculateSingleMaterial(materialId) {
  console.log(`🚀 Starting recalculateSingleMaterial for material ${materialId}`);
  const materialCard = document.querySelector(`[data-material-id="${materialId}"]`);
  if (!materialCard) {
    console.warn(`⚠️ Material card not found for material ${materialId}`);
    return;
  }
  
  // Get current material data from materials_with_processes array
  const materialIndex = formState.productData.materials_with_processes.findIndex(m => m.id == materialId);
  console.log(`🔍 Looking for material ${materialId} in materials_with_processes, found index: ${materialIndex}`);
  if (materialIndex === -1) {
    console.warn(`⚠️ Material ${materialId} not found in materials_with_processes array`);
    console.log('📋 Available materials:', formState.productData.materials_with_processes.map(m => ({ id: m.id, description: m.description })));
    return;
  }
  
  const originalMaterial = formState.productData.materials_with_processes[materialIndex];
  const materialData = formState.productData.materials[materialId] || {};
  
  // Get product dimensions
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Create updated material object using the current values from materials_with_processes (which should be the most up-to-date)
  const updatedMaterial = {
    ...originalMaterial,
    // Use the values from materials_with_processes as they are already updated
    ancho: originalMaterial.ancho,
    largo: originalMaterial.largo,
    cost: originalMaterial.cost || originalMaterial.price,
    price: originalMaterial.cost || originalMaterial.price,
    description: originalMaterial.description
  };
  
  console.log(`🔍 Material recalculation debug:`, {
    materialId,
    originalMaterial: { ancho: originalMaterial.ancho, largo: originalMaterial.largo },
    materialData: { ancho: materialData.ancho, largo: materialData.largo },
    updatedMaterial: { ancho: updatedMaterial.ancho, largo: updatedMaterial.largo },
    productDimensions: { width: productWidth, length: productLength, quantity: productQuantity }
  });
  
  // Calculate new values
  const calculatedData = calculateMaterialData(updatedMaterial, productQuantity, productWidth, productLength);
  
  console.log(`📊 Calculated data for material ${materialId}:`, {
    piecesPerMaterial: calculatedData.piecesPerMaterial,
    totalSheets: calculatedData.totalSheets,
    totalSquareMeters: calculatedData.totalSquareMeters,
    totalPrice: calculatedData.totalPrice
  });
  
  // Override pieces if it was manually edited
  if (materialData.pieces) {
    calculatedData.piecesPerMaterial = materialData.pieces;
    // Recalculate sheets based on manual pieces
    calculatedData.totalSheets = Math.ceil(productQuantity / materialData.pieces);
    // Recalculate total price based on manual pieces
    const sheetsNeeded = calculatedData.totalSheets;
    const materialPrice = parseFloat(updatedMaterial.cost || updatedMaterial.price) || 0;
    const materialWidth = parseFloat(updatedMaterial.ancho) || 0;
    const materialLength = parseFloat(updatedMaterial.largo) || 0;
    
    if (isWeightBasedMaterial(updatedMaterial)) {
      const materialWeight = parseFloat(updatedMaterial.weight) || 0;
      calculatedData.totalWeight = sheetsNeeded * materialWeight;
      calculatedData.totalPrice = calculatedData.totalWeight * materialPrice;
    } else if (isAreaBasedMaterial(updatedMaterial)) {
      const totalSquareMeters = sheetsNeeded * (materialWidth * materialLength) / 10000;
      calculatedData.totalSquareMeters = totalSquareMeters.toFixed(2);
      calculatedData.totalPrice = totalSquareMeters * materialPrice;
    } else {
      calculatedData.totalPrice = sheetsNeeded * materialPrice;
    }
    
    console.log(`🔢 Override pieces calculation: ${calculatedData.piecesPerMaterial} pieces, ${calculatedData.totalSheets} sheets, $${calculatedData.totalPrice} total`);
  }
  
  // Update the material in materials_with_processes array with the updated values
  formState.productData.materials_with_processes[materialIndex] = updatedMaterial;
  
  // Update calculated values in the UI
  updateMaterialCardDisplay(materialCard, calculatedData);
}

// Update material card display
function updateMaterialCardDisplay(materialCard, calculatedData, preserveEditableFields = false) {
  // Update calculated values (always update these)
  const sheetsElement = materialCard.querySelector('[data-field="sheets"]');
  if (sheetsElement) {
    console.log(`📄 Updating sheets: ${sheetsElement.textContent} → ${calculatedData.totalSheets}`);
    sheetsElement.textContent = calculatedData.totalSheets;
  } else {
    console.warn('⚠️ Sheets element not found!');
  }
  
  const weightElement = materialCard.querySelector('[data-field="weight"]');
  if (weightElement) {
    weightElement.textContent = calculatedData.totalWeight;
  }
  
  const squareMetersElement = materialCard.querySelector('[data-field="squareMeters"]');
  if (squareMetersElement) {
    squareMetersElement.textContent = calculatedData.isWeightBased ? '-' : calculatedData.totalSquareMeters;
  }
  
  const totalCostElement = materialCard.querySelector('[data-field="totalCost"]');
  if (totalCostElement) {
    totalCostElement.textContent = formatCurrency(calculatedData.totalPrice);
  }
  
  // Only update editable fields if not preserving them
  if (!preserveEditableFields) {
    // Update pieces field if it exists and is not focused
    const piecesField = materialCard.querySelector('[data-field="pieces"]');
    if (piecesField && !piecesField.matches(':focus')) {
      piecesField.value = calculatedData.piecesPerMaterial;
    }
  } else {
    // When preserving editable fields, still update pieces if it wasn't manually edited
    const piecesField = materialCard.querySelector('[data-field="pieces"]');
    if (piecesField && !piecesField.matches(':focus')) {
      // Only update if the current value is different from calculated
      const currentValue = parseFloat(piecesField.value) || 0;
      if (currentValue !== calculatedData.piecesPerMaterial) {
        piecesField.value = calculatedData.piecesPerMaterial;
      }
    }
  }
}

function updateMaterialQuantity(event) {
  const materialId = event.target.dataset.materialId;
  const quantity = parseFloat(event.target.value) || 1;
  
  console.log(`📊 Updating quantity for material ${materialId}: ${quantity}`);
  
  // Update in formState
  // Implementation will be added when we handle form submission
}

function addProcessToMaterial(event) {
  const materialId = event.target.dataset.materialId;
  const materialCard = event.target.closest('.material-card');
  const processSelector = materialCard.querySelector('.process-selector');
  const selectedOption = processSelector.options[processSelector.selectedIndex];
  
  if (!selectedOption.value) {
    showValidationMessage('Por favor selecciona un proceso para agregar.');
    return;
  }
  
  const processData = JSON.parse(selectedOption.dataset.process);
  console.log(`➕ Adding process ${processData.description} to material ${materialId}`);
  
  // Check if process is already added
  const selectedProcessesContainer = materialCard.querySelector('.selected-processes');
  const existingProcess = selectedProcessesContainer.querySelector(`[data-process-id="${processData.id}"]`);
  
  if (existingProcess) {
    showValidationMessage('Este proceso ya está agregado a este material.');
    return;
  }
  
  // Check if this is the first process - create unified container
  const existingProcesses = selectedProcessesContainer.querySelectorAll('.process-row');
  if (existingProcesses.length === 0) {
    // Create unified container for processes
    const unifiedContainer = `
      <div class="material-card processes-unified-container" data-material-id="${materialId}">
        <div class="material-info">
          <div class="material-details">
            <div class="processes-container">
              <!-- Processes will be added here -->
            </div>
          </div>
        </div>
      </div>
    `;
    selectedProcessesContainer.insertAdjacentHTML('beforeend', unifiedContainer);
  }
  
  // Create process row
  const processRow = createProcessRow(processData, materialId);
  const processesContainer = selectedProcessesContainer.querySelector('.processes-container');
  processesContainer.insertAdjacentHTML('beforeend', processRow);
  
  // Bind remove event to the new row
  const newRow = processesContainer.lastElementChild;
  const removeBtn = newRow.querySelector('.remove-process-btn');
  if (removeBtn) {
    removeBtn.addEventListener('click', removeProcessFromMaterial);
  }
  
  // Bind editable process fields
  const processFields = newRow.querySelectorAll('.process-field');
  processFields.forEach(field => {
    field.addEventListener('input', handleProcessFieldChange);
    field.addEventListener('change', handleProcessFieldChange);
    console.log('✅ Process field bound:', field.dataset.field, 'for process', field.dataset.processId);
  });
  
  // Reset selector
  processSelector.selectedIndex = 0;
  
  console.log(`✅ Process ${processData.description} added to material ${materialId}`);
  showValidationMessage(`Proceso "${processData.description}" agregado correctamente`, 'success');
  
  // Trigger recalculation
  triggerRecalculation();
}

function addManualProcessToMaterial(event) {
  const materialId = event.target.dataset.materialId;
  const materialCard = event.target.closest('.material-card');
  const selectedProcessesContainer = materialCard.querySelector('.selected-processes');
  
  console.log(`➕ Adding manual process to material ${materialId}`);
  
  // Create a new manual process with default values
  const manualProcess = {
    id: 'manual_' + Date.now(), // Unique ID for manual processes
    description: 'Proceso nuevo',
    price: 0,
    unit: 'pieza',
    manual: true
  };
  
  console.log('📦 Creating manual process:', manualProcess);
  
  // Check if this is the first process - create unified container
  const existingProcesses = selectedProcessesContainer.querySelectorAll('.process-row');
  if (existingProcesses.length === 0) {
    // Create unified container for processes
    const unifiedContainer = `
      <div class="material-card processes-unified-container" data-material-id="${materialId}">
        <div class="material-info">
          <div class="material-details">
            <div class="processes-container">
              <!-- Processes will be added here -->
            </div>
          </div>
        </div>
      </div>
    `;
    selectedProcessesContainer.insertAdjacentHTML('beforeend', unifiedContainer);
  }
  
  // Create process row
  const processRow = createManualProcessRow(manualProcess, materialId);
  const processesContainer = selectedProcessesContainer.querySelector('.processes-container');
  processesContainer.insertAdjacentHTML('beforeend', processRow);
  
  // Bind remove event to the new row
  const newRow = processesContainer.lastElementChild;
  const removeBtn = newRow.querySelector('.remove-process-btn');
  if (removeBtn) {
    removeBtn.addEventListener('click', removeProcessFromMaterial);
  }
  
  // Bind editable process fields
  const processFields = newRow.querySelectorAll('.process-field');
  processFields.forEach(field => {
    field.addEventListener('input', handleProcessFieldChange);
    field.addEventListener('change', handleProcessFieldChange);
    
    // For select fields, also listen to change events more explicitly
    if (field.tagName === 'SELECT') {
      field.addEventListener('change', function(event) {
        console.log('🔄 Manual process select field changed:', event.target.dataset.field, 'to:', event.target.value);
        handleProcessFieldChange(event);
      });
    }
    
    console.log('✅ Manual process field bound:', field.dataset.field, 'for process', field.dataset.processId);
  });
  
  // Focus on the description field for better UX
  const descriptionField = newRow.querySelector('input[data-field="description"]');
  if (descriptionField) {
    descriptionField.focus();
    descriptionField.select(); // Select the default text so user can type immediately
  }
  
  console.log(`✅ Manual process ${manualProcess.description} added to material ${materialId}`);
  showValidationMessage('Proceso manual agregado correctamente', 'success');
  
  // Trigger recalculation
  triggerRecalculation();
}

function createManualProcessRow(process, materialId) {
  console.log('🏗️ Creating manual process row for:', process.description);
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Get material data for calculations
  const materialData = getMaterialCalculatedData(materialId, productQuantity, productWidth, productLength);
  
  // Calculate process data
  const calculatedData = calculateProcessData(process, materialData, productQuantity, productWidth, productLength);
  
  // Create unit options - only m2 and pliegos
  const allowedUnits = formState.availableUnits.filter(unit => 
    unit.name.toLowerCase().includes('m2') || 
    unit.name.toLowerCase().includes('mt2') || 
    unit.name.toLowerCase().includes('pliego')
  );
  
  const unitOptions = allowedUnits.map(unit => 
    `<option value="${unit.id}" data-unit-name="${unit.name}" data-unit-abbr="${unit.abbreviation}">${unit.name}</option>`
  ).join('');
  
  return `
    <div class="process-row" data-process-id="${process.id}" data-material-id="${materialId}">
      <div class="row">
        <div class="col-md-6">
          <small class="text-muted">Proceso:</small><br>
          <input type="text" class="form-control form-control-sm process-field"
                 data-field="description" data-process-id="${process.id}" data-material-id="${materialId}"
                 value="${process.description}"
                 style="text-align: left;">
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Unidad:</small><br>
          <select class="form-control form-control-sm process-field"
                  data-field="unit" data-process-id="${process.id}" data-material-id="${materialId}"
                  style="width: 90px; display: inline-block;">
            <option value="">Seleccionar</option>
            ${unitOptions}
          </select>
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Costo</small><br>
          <input type="number" class="form-control form-control-sm process-field"
                 data-field="cost" data-process-id="${process.id}" data-material-id="${materialId}"
                 value="${process.price || 0}" min="0" step="0.01" 
                 style="width: 80px; display: inline-block;">
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Cara</small><br>
          <select class="form-control form-control-sm process-field" 
                  data-field="side" data-process-id="${process.id}" data-material-id="${materialId}"
                  style="width: 90px; display: inline-block;">
            <option value="front">Frente</option>
            <option value="back">Reverso</option>
            <option value="both">Ambas</option>
          </select>
        </div>
        <div class="col-md-2 text-end">
          <small class="text-muted">Total:</small><br>
          <strong class="total-cost">${formatCurrency(calculatedData.totalPrice)}</strong>
        </div>
        <div class="col-md-1 d-flex justify-content-end align-items-center">
          <small class="text-muted">&nbsp;</small><br>
          <button type="button" class="btn btn-sm btn-outline-danger remove-process-btn" data-process-id="${process.id}" data-material-id="${materialId}">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

function createProcessRow(process, materialId) {
  console.log('🔧 createProcessRow called - UNIFIED CONTAINER STRUCTURE');
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Get material data from the card's calculated values
  const materialData = getMaterialCalculatedData(materialId, productQuantity, productWidth, productLength);
  
  // Calculate process data
  const calculatedProcessData = calculateProcessData(process, materialData, productQuantity, productWidth, productLength);
  
  return `
    <div class="process-row" data-process-id="${process.id}" data-material-id="${materialId}">
      <div class="row">
        <div class="col-md-6">
          <small class="text-muted">Proceso:</small><br>
          <strong>${process.description}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Unidad:</small><br>
          <strong>${process.unit || 'pieza'}</strong>
        </div>
        <!-- Hidden times field - always value 1 -->
        <input type="hidden" class="process-field" 
               data-field="times" data-process-id="${process.id}" data-material-id="${materialId}"
               value="1">
        <div class="col-md-1 text-center">
          <small class="text-muted">Costo</small><br>
          <input type="number" class="form-control form-control-sm process-field" 
                 data-field="cost" data-process-id="${process.id}" data-material-id="${materialId}"
                 value="${process.price || 0}" min="0" step="0.01" 
                 style="width: 80px; display: inline-block;">
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Cara</small><br>
          <select class="form-control form-control-sm process-field" 
                  data-field="side" data-process-id="${process.id}" data-material-id="${materialId}"
                  style="width: 90px; display: inline-block;">
            <option value="front">Frente</option>
            <option value="back">Reverso</option>
            <option value="both">Ambas</option>
          </select>
        </div>
        <div class="col-md-2 text-end">
          <small class="text-muted">Total:</small><br>
          <strong class="total-cost">${formatCurrency(calculatedProcessData.totalPrice)}</strong>
        </div>
        <div class="col-md-1 d-flex justify-content-end align-items-center">
          <small class="text-muted">&nbsp;</small><br>
          <button type="button" class="btn btn-sm btn-outline-danger remove-process-btn" 
                  data-process-id="${process.id}" data-material-id="${materialId}">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

function getMaterialCalculatedData(materialId, productQuantity, productWidth, productLength) {
  // Get the material from our formState
  const material = formState.productData.materials_with_processes.find(m => m.id == materialId);
  if (!material) {
    console.error(`❌ Material ${materialId} not found in formState.productData.materials_with_processes`);
    console.log('📋 Available materials:', formState.productData.materials_with_processes);
    return {};
  }
  
  // Calculate material data using the same logic as createMaterialCard
  return calculateMaterialData(material, productQuantity, productWidth, productLength);
}

function calculateProcessData(process, materialData, productQuantity = 1, productWidth = 0, productLength = 0) {
  console.log('🧮 Calculating process data for:', process.description);
  
  const basePrice = parseFloat(process.cost) || parseFloat(process.price) || 0;
  const veces = process.times || 1; // Use edited value or default
  const side = process.side || 'front'; // Use edited value or default
  const sideMultiplier = side === 'both' ? 2 : 1;
  
  let calculatedPrice = basePrice;
  const unitStr = (process.unit || '').toLowerCase();
  
  console.log('📊 Process calculation inputs:', {
    basePrice,
    veces,
    side,
    sideMultiplier,
    unitStr,
    materialData,
    productQuantity,
    productWidth,
    productLength,
    processCost: process.cost,
    processPrice: process.price
  });
  
  // DEBUG: Check if we have valid material data
  if (!materialData || Object.keys(materialData).length === 0) {
    console.error('❌ Material data is empty or invalid:', materialData);
    return { totalPrice: 0, basePrice, veces, side, sideMultiplier };
  }
  
  // DEBUG: Check if we have valid process price
  if (basePrice === 0) {
    console.warn('⚠️ Process base price is 0, check process.cost and process.price:', { cost: process.cost, price: process.price });
  }
  
  if (unitStr.includes('pieza')) {
    // Per piece
    calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
    console.log(`💰 Per piece calculation: ${basePrice} * ${productQuantity} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
  } else if (unitStr.includes('pliego')) {
    // Per sheet - use material's total sheets
    const totalSheets = materialData.totalSheets || 0;
    calculatedPrice = basePrice * totalSheets * veces * sideMultiplier;
    console.log(`📄 Per sheet calculation: ${basePrice} * ${totalSheets} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
  } else if (unitStr.includes('m2') || unitStr.includes('mt2')) {
    // Per square meter - consider material type
    const isWeightBased = isWeightBasedMaterial(materialData);
    if (isWeightBased) {
      // For weight-based materials, use total weight (in kg) instead of square meters
      const totalWeightKg = (materialData.totalWeight || 0) / 1000;
      calculatedPrice = basePrice * totalWeightKg * veces * sideMultiplier;
      console.log(`⚖️ Weight-based calculation: ${basePrice} * ${totalWeightKg} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
    } else {
      // For area-based materials, use square meters
      const totalSquareMeters = materialData.totalSquareMeters || 0;
      calculatedPrice = basePrice * totalSquareMeters * veces * sideMultiplier;
      console.log(`📏 Area-based calculation: ${basePrice} * ${totalSquareMeters} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
    }
  } else {
    // Default: per unit
    calculatedPrice = basePrice * veces * sideMultiplier;
    console.log(`🔢 Default calculation: ${basePrice} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
  }
  
  console.log(`✅ Final calculated price: ${calculatedPrice}`);
  
  // Calculate area and pieces for display
  let area = '-';
  let pieces = '-';
  
  if (unitStr.includes('m2') || unitStr.includes('mt2')) {
    if (isWeightBasedMaterial(materialData)) {
      area = `${(materialData.totalWeight || 0) / 1000} kg`;
    } else {
      area = `${parseFloat(materialData.totalSquareMeters || 0).toFixed(2)} m²`;
    }
  } else if (unitStr.includes('pliego')) {
    area = `${materialData.totalSheets || 0} pliegos`;
  }
  
  if (unitStr.includes('pieza')) {
    pieces = `${productQuantity || 0} piezas`;
  } else if (unitStr.includes('pliego')) {
    pieces = `${materialData.totalSheets || 0} pliegos`;
  }
  
  return {
    basePrice,
    veces,
    side,
    sideMultiplier,
    totalPrice: calculatedPrice,
    area,
    pieces,
    quantity: veces
  };
}

function calculateGlobalProcessData(process, productQuantity = 1, productWidth = 0, productLength = 0, side = 'both') {
  console.log('🌍 Calculating global process data for:', process.description);
  
  const basePrice = parseFloat(process.price) || 0;
  const veces = 1; // Default value, will be updated from input
  const sideMultiplier = side === 'both' ? 2 : 1;
  
  let calculatedPrice = basePrice;
  const unitStr = (process.unit || '').toLowerCase();
  
  console.log('📊 Global process calculation inputs:', {
    basePrice,
    veces,
    side,
    sideMultiplier,
    unitStr,
    productQuantity,
    productWidth,
    productLength
  });
  
  if (unitStr.includes('pieza') || unitStr.includes('pza')) {
    // Per piece - multiply by product quantity
    calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
    console.log(`💰 Per piece calculation: ${basePrice} * ${productQuantity} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
  } else if (unitStr.includes('millar') || unitStr.includes('mil')) {
    // Per thousand - divide by 1000
    calculatedPrice = (basePrice * productQuantity * veces * sideMultiplier) / 1000;
    console.log(`📊 Per thousand calculation: (${basePrice} * ${productQuantity} * ${veces} * ${sideMultiplier}) / 1000 = ${calculatedPrice}`);
  } else {
    // Default: per piece (same as pieza)
    calculatedPrice = basePrice * productQuantity * veces * sideMultiplier;
    console.log(`🔢 Default calculation: ${basePrice} * ${productQuantity} * ${veces} * ${sideMultiplier} = ${calculatedPrice}`);
  }
  
  console.log(`✅ Final calculated price: ${calculatedPrice}`);
  
  return {
    basePrice,
    veces,
    side,
    sideMultiplier,
    totalPrice: calculatedPrice
  };
}

function removeProcessFromMaterial(event) {
  const processId = event.target.dataset.processId;
  const materialId = event.target.dataset.materialId;
  const processRow = event.target.closest('.process-row');
  
  console.log(`🗑️ Removing process ${processId} from material ${materialId}`);
  
  if (processRow) {
    console.log(`🗑️ Removing process row:`, processRow);
    processRow.remove();
    
    // Check if this was the last process - remove unified container
    const materialCard = document.querySelector(`[data-material-id="${materialId}"]:not(.processes-unified-container)`);
    console.log(`🔍 Material card found:`, materialCard);
    
    const processesContainer = materialCard?.querySelector('.processes-container');
    console.log(`🔍 Processes container:`, processesContainer);
    
    const remainingProcesses = processesContainer?.querySelectorAll('.process-row');
    console.log(`🔍 Remaining processes: ${remainingProcesses?.length || 0}`);
    console.log(`🔍 Remaining processes elements:`, remainingProcesses);
    
    if (remainingProcesses && remainingProcesses.length === 0) {
      console.log(`🗑️ No processes remaining, removing unified container`);
      // Remove the unified container
      const unifiedContainer = materialCard?.querySelector('.processes-unified-container');
      console.log(`🗑️ Unified container to remove:`, unifiedContainer);
      if (unifiedContainer) {
        unifiedContainer.remove();
        console.log(`✅ Unified container removed successfully`);
      } else {
        // Try to find it in the selected-processes container
        const selectedProcessesContainer = materialCard?.querySelector('.selected-processes');
        const unifiedContainerAlt = selectedProcessesContainer?.querySelector('.processes-unified-container');
        console.log(`🗑️ Alternative unified container to remove:`, unifiedContainerAlt);
        if (unifiedContainerAlt) {
          unifiedContainerAlt.remove();
          console.log(`✅ Alternative unified container removed successfully`);
        }
      }
    }
    
    showValidationMessage('Proceso eliminado correctamente', 'success');
    
    // Trigger recalculation
    triggerRecalculation();
  } else {
    console.error(`❌ Process row not found for removal`);
  }
}

function removeMaterial(event) {
  // Handle clicks on the icon or button
  const button = event.target.closest('button');
  const materialId = button?.dataset.materialId || event.target.dataset.materialId;
  const materialCard = event.target.closest('.material-card');
  
  console.log(`🗑️ Removing material ${materialId}`);
  
  // Remove from formState
  const materialIndex = formState.productData.materials_with_processes.findIndex(m => m.id == materialId);
  if (materialIndex !== -1) {
    formState.productData.materials_with_processes.splice(materialIndex, 1);
    console.log('💾 Material removed from formState:', formState.productData.materials_with_processes);
  }
  
  if (materialCard) {
    materialCard.remove();
    showValidationMessage('Material eliminado correctamente', 'success');
    
    // Trigger recalculation
    triggerRecalculation();
  }
}

// Utility functions
function showValidationMessage(message, type = 'error') {
  console.log(`💬 Showing ${type} message:`, message);
  
  // Remove any existing message
  const existingMessage = document.querySelector('.validation-message');
  if (existingMessage) {
    existingMessage.remove();
  }
  
  // Create new message
  const messageDiv = document.createElement('div');
  messageDiv.className = `alert alert-${type === 'error' ? 'danger' : 'success'} validation-message`;
  messageDiv.textContent = message;
  
  // Add to form
  const form = document.getElementById('product-form-v3');
  if (form) {
    form.insertBefore(messageDiv, form.firstChild);
    
    // Auto-remove after 3 seconds
    setTimeout(() => {
      if (messageDiv.parentElement) {
        messageDiv.remove();
      }
    }, 3000);
  }
}

// Global processes functions
function populateGlobalProcessSelect(processes) {
  console.log('🌍 Populating global process select with', processes.length, 'processes');
  
  const globalProcessSelect = document.getElementById('global-process-select');
  if (!globalProcessSelect) {
    console.error('❌ Global process select element not found!');
    return;
  }
  
  // Clear existing options except the first one
  globalProcessSelect.innerHTML = '<option value="">Selecciona un proceso global...</option>';
  
  // Filter processes to only show those with unit "piezas"
  const piezasProcesses = processes.filter(process => {
    const unit = (process.unit || '').toLowerCase();
    return unit === 'piezas' || unit === 'pieza';
  });
  
  console.log(`🔍 Filtered ${piezasProcesses.length} processes with unit "piezas" from ${processes.length} total processes`);
  
  // Add filtered processes to dropdown
  piezasProcesses.forEach((process, index) => {
    const option = document.createElement('option');
    option.value = process.id;
    option.textContent = process.description;
    option.dataset.process = JSON.stringify(process);
    globalProcessSelect.appendChild(option);
    console.log(`✅ Added process option: ${process.description} (ID: ${process.id}, Unit: ${process.unit})`);
  });
  
  console.log(`✅ Global process select populated with ${processes.length} processes`);
}

function addGlobalProcess() {
  console.log('🌍 Adding global process...');
  
  const globalProcessSelect = document.getElementById('global-process-select');
  const processSideSelect = document.getElementById('process-side');
  
  console.log('🔍 Global process select element:', globalProcessSelect);
  console.log('🔍 Global process select options count:', globalProcessSelect?.options?.length || 0);
  console.log('🔍 Global process select selected index:', globalProcessSelect?.selectedIndex || -1);
  
  const selectedOption = globalProcessSelect.options[globalProcessSelect.selectedIndex];
  
  console.log('🔍 Selected option:', selectedOption);
  console.log('🔍 Selected option value:', selectedOption?.value);
  
  if (!selectedOption.value) {
    console.log('❌ No process selected');
    showValidationMessage('Por favor selecciona un proceso global.');
    return;
  }
  
  const processData = JSON.parse(selectedOption.dataset.process);
  const processSide = processSideSelect.value;
  
  console.log(`➕ Adding global process ${processData.description} to ${processSide}`);
  
  // Check if process is already added with same side
  const globalProcessesList = document.getElementById('global-processes-list');
  const existingProcess = globalProcessesList.querySelector(`.material-card[data-process-id="${processData.id}"][data-side="${processSide}"]`);
  
  if (existingProcess) {
    showValidationMessage(`Este proceso ya está agregado para ${processSide}.`);
    return;
  }
  
  // Check if this is the first process - create unified container like material processes
  const existingProcesses = globalProcessesList.querySelectorAll('.process-row');
  if (existingProcesses.length === 0) {
    // Create unified container for global processes (same structure as material processes)
    const unifiedContainer = `
      <div class="material-card processes-unified-container" data-global-processes="true">
        <div class="material-info">
          <div class="material-details">
            <div class="processes-container">
              <!-- Global processes will be added here -->
            </div>
          </div>
        </div>
      </div>
    `;
    globalProcessesList.insertAdjacentHTML('beforeend', unifiedContainer);
    
    // Show container when first process is added
    const globalProcessesContainer = document.getElementById('global-processes-container');
    if (globalProcessesContainer) {
      globalProcessesContainer.style.display = 'block';
    }
  }
  
  // Create process row (same structure as material processes)
  const processRow = createGlobalProcessRow(processData, processSide);
  const processesContainer = globalProcessesList.querySelector('.processes-container');
  processesContainer.insertAdjacentHTML('beforeend', processRow);
  
  // Bind remove event to the new item
  const newItem = processesContainer.lastElementChild;
  const removeBtn = newItem.querySelector('.remove-global-process');
  if (removeBtn) {
    removeBtn.addEventListener('click', removeGlobalProcess);
    console.log(`✅ Remove button bound for global process ${processData.id}`);
  } else {
    console.error(`❌ Remove button not found for global process ${processData.id}`);
  }
  
  // Reset selectors
  globalProcessSelect.selectedIndex = 0;
  processSideSelect.selectedIndex = 0;
  
  console.log(`✅ Global process ${processData.description} added for ${processSide}`);
  showValidationMessage(`Proceso global "${processData.description}" agregado correctamente`, 'success');
  
  // Trigger recalculation
  triggerRecalculation();
}

function createGlobalProcessRow(process, side) {
  console.log('🌍 createGlobalProcessRow called - EXACT SAME STRUCTURE AS MATERIAL PROCESSES');
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Calculate global process data
  const calculatedProcessData = calculateGlobalProcessData(process, productQuantity, productWidth, productLength, side);
  
  const sideText = {
    'front': 'Frente',
    'back': 'Reverso', 
    'both': 'Ambas'
  };
  
  return `
    <div class="process-row" data-process-id="${process.id}" data-side="${side}">
      <div class="row">
        <div class="col-md-6">
          <small class="text-muted">Proceso:</small><br>
          <strong>${process.description}</strong>
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Unidad:</small><br>
          <strong>${process.unit || 'pieza'}</strong>
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Costo:</small><br>
          <strong>${formatCurrency(process.price || 0)}</strong>
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Cara:</small><br>
          <strong>${sideText[side]}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Piezas:</small><br>
          <strong>${productQuantity}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Total:</small><br>
          <strong class="total-cost">${formatCurrency(calculatedProcessData.totalPrice)}</strong>
        </div>
        <div class="col-md-1 d-flex justify-content-end align-items-center">
          <small class="text-muted">&nbsp;</small><br>
          <button type="button" class="btn btn-sm btn-outline-danger remove-global-process" 
                  data-process-id="${process.id}" data-side="${side}">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

function createManualGlobalProcessRow(process, side) {
  console.log('🏗️ Creating manual global process row for:', process.description);
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Calculate global process data
  const calculatedProcessData = calculateGlobalProcessData(process, productQuantity, productWidth, productLength, side);
  
  const sideText = {
    'front': 'Frente',
    'back': 'Reverso', 
    'both': 'Ambas'
  };
  
  return `
    <div class="process-row" data-process-id="${process.id}" data-side="${side}">
      <div class="row">
        <div class="col-md-6">
          <small class="text-muted">Proceso:</small><br>
          <input type="text" class="form-control form-control-sm manual-global-process-field"
                 data-field="description" data-process-id="${process.id}" data-side="${side}"
                 value="${process.description}" placeholder="Nombre del proceso">
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Unidad:</small><br>
          <strong>${process.unit || 'pieza'}</strong>
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Costo:</small><br>
          <input type="number" class="form-control form-control-sm manual-global-process-field"
                 data-field="price" data-process-id="${process.id}" data-side="${side}"
                 value="${process.price || 0}" min="0" step="0.01" placeholder="0.00">
        </div>
        <div class="col-md-1 text-center">
          <small class="text-muted">Cara:</small><br>
          <strong>${sideText[side]}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Piezas:</small><br>
          <strong>${productQuantity}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Total:</small><br>
          <strong class="total-cost">${formatCurrency(calculatedProcessData.totalPrice)}</strong>
        </div>
        <div class="col-md-1 d-flex justify-content-end align-items-center">
          <small class="text-muted">&nbsp;</small><br>
          <button type="button" class="btn btn-sm btn-outline-danger remove-global-process" 
                  data-process-id="${process.id}" data-side="${side}">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

function addManualGlobalProcess() {
  console.log('🌍 Adding manual global process...');
  
  const globalProcessesList = document.getElementById('global-processes-list');
  const processSideSelect = document.getElementById('process-side');
  const processSide = processSideSelect.value;
  
  // Create a new manual global process with default values
  const manualProcess = {
    id: 'manual_global_' + Date.now(), // Unique ID for manual global processes
    description: 'Proceso global nuevo',
    price: 0,
    unit: 'pieza',
    manual: true
  };
  
  console.log('📦 Creating manual global process:', manualProcess);
  
  // Add to formState
  if (!formState.productData.globalProcesses) {
    formState.productData.globalProcesses = {};
  }
  formState.productData.globalProcesses[manualProcess.id] = {
    description: manualProcess.description,
    price: manualProcess.price,
    side: processSide,
    manual: true
  };
  
  // Check if this is the first process - create unified container like material processes
  const existingProcesses = globalProcessesList.querySelectorAll('.process-row');
  if (existingProcesses.length === 0) {
    // Create unified container for global processes (same structure as material processes)
    const unifiedContainer = `
      <div class="material-card processes-unified-container" data-global-processes="true">
        <div class="material-info">
          <div class="material-details">
            <div class="processes-container">
              <!-- Global processes will be added here -->
            </div>
          </div>
        </div>
      </div>
    `;
    globalProcessesList.insertAdjacentHTML('beforeend', unifiedContainer);
    
    // Show container when first process is added
    const globalProcessesContainer = document.getElementById('global-processes-container');
    if (globalProcessesContainer) {
      globalProcessesContainer.style.display = 'block';
    }
  }
  
  // Create manual process row (same structure as material processes)
  const processRow = createManualGlobalProcessRow(manualProcess, processSide);
  const processesContainer = globalProcessesList.querySelector('.processes-container');
  processesContainer.insertAdjacentHTML('beforeend', processRow);
  
  // Bind remove event to the new item
  const newItem = processesContainer.lastElementChild;
  const removeBtn = newItem.querySelector('.remove-global-process');
  if (removeBtn) {
    removeBtn.addEventListener('click', removeGlobalProcess);
    console.log(`✅ Remove button bound for manual global process ${manualProcess.id}`);
  } else {
    console.error(`❌ Remove button not found for manual global process ${manualProcess.id}`);
  }
  
  // Bind editable fields
  bindManualGlobalProcessEvents(newItem);
  
  // Reset side selector
  processSideSelect.selectedIndex = 0;
  
  console.log(`✅ Manual global process ${manualProcess.description} added for ${processSide}`);
  showValidationMessage(`Proceso global manual "${manualProcess.description}" agregado correctamente`, 'success');
  
  // Trigger recalculation
  triggerRecalculation();
}

function createManualGlobalProcessItem(process, side) {
  console.log('🌍 createManualGlobalProcessItem called - MANUAL PROCESS LAYOUT');
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Calculate global process data
  const calculatedProcessData = calculateGlobalProcessData(process, productQuantity, productWidth, productLength, side);
  
  const sideText = {
    'front': 'Frente',
    'back': 'Reverso', 
    'both': 'Ambas'
  };
  
  return `
    <div class="material-card" data-process-id="${process.id}" data-side="${side}">
      <div class="material-info">
        <div class="material-details">
          <div class="row">
            <div class="col-md-6">
              <small class="text-muted">Proceso:</small><br>
              <input type="text" class="form-control form-control-sm manual-global-process-field" 
                     data-field="description" data-process-id="${process.id}" 
                     value="${process.description}" 
                     style="width: 100%; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Unidad:</small><br>
              <strong>Pieza</strong>
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Costo:</small><br>
              <input type="number" class="form-control form-control-sm manual-global-process-field" 
                     data-field="price" data-process-id="${process.id}" 
                     value="${process.price}" min="0" step="0.01" 
                     style="width: 90px; display: inline-block;">
            </div>
            <div class="col-md-1 text-center">
              <small class="text-muted">Cara:</small><br>
              <select class="form-select form-select-sm manual-global-process-field" 
                      data-field="side" data-process-id="${process.id}" 
                      style="width: 90px; display: inline-block;">
                <option value="front" ${side === 'front' ? 'selected' : ''}>Frente</option>
                <option value="back" ${side === 'back' ? 'selected' : ''}>Reverso</option>
                <option value="both" ${side === 'both' ? 'selected' : ''}>Ambas</option>
              </select>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Piezas:</small><br>
              <strong>${productQuantity}</strong>
            </div>
            <div class="col-md-1 text-end">
              <small class="text-muted">Total:</small><br>
              <strong class="total-cost">${formatCurrency(calculatedProcessData.totalPrice)}</strong>
            </div>
            <div class="col-md-1 d-flex justify-content-end align-items-center">
              <small class="text-muted">&nbsp;</small><br>
              <button type="button" class="btn btn-sm btn-outline-danger remove-global-process" 
                      data-process-id="${process.id}" data-side="${side}">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
}

function bindManualGlobalProcessEvents(processItem) {
  console.log('🔗 Binding events for manual global process...');
  
  // Bind editable fields
  const processFields = processItem.querySelectorAll('.manual-global-process-field');
  processFields.forEach(field => {
    field.addEventListener('input', handleManualGlobalProcessFieldChange);
    field.addEventListener('change', handleManualGlobalProcessFieldChange);
    console.log('✅ Manual global process field bound:', field.dataset.field, 'for process', field.dataset.processId);
  });
  
  console.log('✅ Manual global process events bound');
}

function handleManualGlobalProcessFieldChange(event) {
  const field = event.target;
  const processId = field.dataset.processId;
  const fieldName = field.dataset.field;
  const newValue = fieldName === 'description' ? field.value : (parseFloat(field.value) || 0);
  
  console.log(`📝 Manual global process field changed: ${fieldName} = ${newValue} for process ${processId}`);
  
  // Update the process data in formState
  if (!formState.productData.globalProcesses) {
    formState.productData.globalProcesses = {};
  }
  
  if (!formState.productData.globalProcesses[processId]) {
    formState.productData.globalProcesses[processId] = {};
  }
  
  formState.productData.globalProcesses[processId][fieldName] = newValue;
  
  // If side changed, update the data-side attribute
  if (fieldName === 'side') {
    const processCard = field.closest('.material-card');
    if (processCard) {
      processCard.dataset.side = newValue;
      console.log(`🔄 Updated data-side attribute to: ${newValue}`);
    }
  }
  
  // Recalculate this process
  console.log(`🔄 About to recalculate manual global process ${processId}`);
  recalculateManualGlobalProcess(processId);
  console.log(`✅ Finished recalculating manual global process ${processId}`);
}

function recalculateManualGlobalProcess(processId) {
  console.log(`🚀 Starting recalculateManualGlobalProcess for process ${processId}`);
  
  const processCard = document.querySelector(`[data-process-id="${processId}"]`);
  if (!processCard) {
    console.warn(`⚠️ Process card not found for process ${processId}`);
    return;
  }
  
  const side = processCard.dataset.side;
  const processData = formState.productData.globalProcesses[processId] || {};
  
  // Create updated process object
  const updatedProcess = {
    id: processId,
    description: processData.description || 'Proceso global manual',
    price: processData.price || 0,
    unit: 'pieza', // Always pieza for manual global processes
    manual: true
  };
  
  // Get product dimensions
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Calculate new values
  const calculatedData = calculateGlobalProcessData(updatedProcess, productQuantity, productWidth, productLength, side);
  
  // Update calculated values in the UI
  updateManualGlobalProcessCardDisplay(processCard, calculatedData, productQuantity);
  
  console.log(`📊 Calculated data for manual global process ${processId}:`, calculatedData);
  
  // Trigger final recalculation to update totals
  triggerRecalculation();
}

function updateManualGlobalProcessCardDisplay(card, calculatedData, productQuantity) {
  // Update total cost
  const totalCostElement = card.querySelector('.total-cost');
  if (totalCostElement) {
    totalCostElement.textContent = formatCurrency(calculatedData.totalPrice);
  }
  
  // Update quantity display
  const quantityElement = card.querySelector('.col-md-1:nth-child(5) strong');
  if (quantityElement) {
    quantityElement.textContent = productQuantity;
  }
}

function removeGlobalProcess(event) {
  const processId = event.target.dataset.processId || event.target.closest('button').dataset.processId;
  const side = event.target.dataset.side || event.target.closest('button').dataset.side;
  const processRow = event.target.closest('.process-row');
  
  console.log(`🗑️ Removing global process ${processId} from ${side}`);
  
  if (processRow) {
    console.log(`🗑️ Removing process row:`, processRow);
    processRow.remove();
    
    // Check if this was the last process - remove unified container like material processes
    const globalProcessesList = document.getElementById('global-processes-list');
    console.log(`🔍 Global processes list:`, globalProcessesList);
    
    const processesContainer = globalProcessesList ? globalProcessesList.querySelector('.processes-container') : null;
    console.log(`🔍 Processes container:`, processesContainer);
    
    const remainingProcesses = processesContainer ? processesContainer.querySelectorAll('.process-row') : [];
    console.log(`🔍 Remaining global processes: ${remainingProcesses?.length || 0}`);
    console.log(`🔍 Remaining processes elements:`, remainingProcesses);
    
    if (remainingProcesses.length === 0) {
      console.log(`🗑️ No processes remaining, removing unified container`);
      // Remove the unified container
      const unifiedContainer = globalProcessesList.querySelector('.processes-unified-container');
      console.log(`🗑️ Unified container to remove:`, unifiedContainer);
      if (unifiedContainer) {
        unifiedContainer.remove();
        console.log(`✅ Unified container removed successfully`);
      }
      
      // Hide main container if no processes remain
      const globalProcessesContainer = document.getElementById('global-processes-container');
      console.log(`🔍 Global processes container to hide:`, globalProcessesContainer);
      if (globalProcessesContainer) {
        globalProcessesContainer.style.display = 'none';
        console.log(`✅ Global processes container hidden`);
      }
    }
    
    showValidationMessage('Proceso global eliminado correctamente', 'success');
    
    // Trigger recalculation
    triggerRecalculation();
  } else {
    console.error(`❌ Process row not found for removal`);
  }
}

// Extras functions
function populateExtraSelect(extras) {
  const extraSelect = document.getElementById('extra-select');
  if (!extraSelect) {
    console.error('❌ Extra select element not found!');
    return;
  }
  
  // Clear existing options except the first one
  extraSelect.innerHTML = '<option value="">Selecciona un costo extra...</option>';
  
  // Add extras to dropdown
  extras.forEach((extra, index) => {
    const option = document.createElement('option');
    option.value = extra.id;
    option.textContent = extra.name;
    option.dataset.extra = JSON.stringify(extra);
    extraSelect.appendChild(option);
  });
}

function addExtra() {
  console.log('💰 Adding extra...');
  
  const extraSelect = document.getElementById('extra-select');
  const quantityInput = document.getElementById('extra-quantity');
  const selectedOption = extraSelect.options[extraSelect.selectedIndex];
  
  if (!selectedOption.value) {
    showValidationMessage('Por favor selecciona un costo extra.');
    return;
  }
  
  const extraData = JSON.parse(selectedOption.dataset.extra);
  const quantity = parseFloat(quantityInput.value) || 1;
  
  console.log(`➕ Adding extra ${extraData.name} with quantity ${quantity}`);
  
  // Check if extra is already added
  const extrasList = document.getElementById('extras-list');
  const existingExtra = extrasList.querySelector(`[data-extra-id="${extraData.id}"]`);
  
  if (existingExtra) {
    showValidationMessage('Este extra ya está agregado.');
    return;
  }
  
  // Check if this is the first extra - create unified container like material processes
  const existingExtras = extrasList.querySelectorAll('.process-row');
  if (existingExtras.length === 0) {
    // Create unified container for extras (same structure as material processes)
    const unifiedContainer = `
      <div class="material-card processes-unified-container" data-extras="true">
        <div class="material-info">
          <div class="material-details">
            <div class="processes-container">
              <!-- Extras will be added here -->
            </div>
          </div>
        </div>
      </div>
    `;
    extrasList.insertAdjacentHTML('beforeend', unifiedContainer);
    
    // Show container when first extra is added
    const extrasContainer = document.getElementById('extras-container');
    if (extrasContainer) {
      extrasContainer.style.display = 'block';
    }
  }
  
  // Create extra row (same structure as material processes)
  const extraRow = createExtraRow(extraData, quantity);
  const processesContainer = extrasList.querySelector('.processes-container');
  processesContainer.insertAdjacentHTML('beforeend', extraRow);
  
  // Bind remove event to the new item
  const newItem = processesContainer.lastElementChild;
  const removeBtn = newItem.querySelector('.remove-extra');
  if (removeBtn) {
    removeBtn.addEventListener('click', removeExtra);
  }
  
  // Bind quantity change event
  const quantityField = newItem.querySelector('.extra-quantity-input');
  if (quantityField) {
    quantityField.addEventListener('change', updateExtraQuantity);
  }
  
  // Reset selectors
  extraSelect.selectedIndex = 0;
  quantityInput.value = 1;
  
  console.log(`✅ Extra ${extraData.name} added with quantity ${quantity}`);
  showValidationMessage(`Extra "${extraData.name}" agregado correctamente`, 'success');
  
  // Trigger recalculation
  triggerRecalculation();
}

function recalculateProcess(event) {
  const processId = event.target.dataset.processId;
  const materialId = event.target.dataset.materialId;
  
  console.log(`🔄 Recalculating process ${processId} for material ${materialId}`);
  
  const processItem = event.target.closest('.process-item');
  const vecesInput = processItem.querySelector('.process-veces');
  const costInput = processItem.querySelector('.process-cost');
  const sideSelect = processItem.querySelector('.process-side');
  const totalCostElement = processItem.querySelector('.process-total-cost');
  
  const veces = parseFloat(vecesInput.value) || 1;
  const cost = parseFloat(costInput.value) || 0;
  const side = sideSelect.value || 'front';
  const sideMultiplier = side === 'both' ? 2 : 1;
  
  // Get product dimensions for calculations
  const productQuantity = parseFloat(document.querySelector('[name="product[quantity]"]')?.value) || 1;
  const productWidth = parseFloat(document.querySelector('[name="width"]')?.value) || 0;
  const productLength = parseFloat(document.querySelector('[name="length"]')?.value) || 0;
  
  // Get material data from formState
  const materialData = getMaterialCalculatedData(materialId, productQuantity, productWidth, productLength);
  
  // Recalculate process data
  const calculatedProcessData = calculateProcessData(
    { price: cost, unit: processItem.querySelector('strong').textContent },
    materialData,
    productQuantity,
    productWidth,
    productLength
  );
  
  // Update total cost display
  if (totalCostElement) {
    totalCostElement.textContent = formatCurrency(calculatedProcessData.totalPrice);
  }
  
  // Update cost input to show proper formatting (2 decimal places)
  if (costInput && costInput.value) {
    const formattedCost = parseFloat(costInput.value).toFixed(2);
    if (costInput.value !== formattedCost) {
      costInput.value = formattedCost;
    }
  }
  
  console.log(`✅ Process recalculated: ${formatCurrency(calculatedProcessData.totalPrice)}`);
}

function createExtraRow(extra, quantity) {
  const totalPrice = extra.unit_price * quantity;
  
  return `
    <div class="process-row" data-extra-id="${extra.id}">
      <div class="row">
        <div class="col-md-7">
          <small class="text-muted">Extra:</small><br>
          <strong>${extra.name}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Unidad:</small><br>
          <strong>${extra.unit || 'Servicio'}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Veces:</small><br>
          <input type="number" class="form-control form-control-sm extra-quantity-input" 
                 value="${quantity}" min="1" data-extra-id="${extra.id}" 
                 data-price="${extra.unit_price}" style="text-align: right;">
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Costo:</small><br>
          <strong>${formatCurrency(extra.unit_price)}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Total:</small><br>
          <strong class="total-cost">${formatCurrency(totalPrice)}</strong>
        </div>
        <div class="col-md-1 d-flex justify-content-end align-items-center">
          <small class="text-muted">&nbsp;</small><br>
          <button type="button" class="btn btn-sm btn-outline-danger remove-extra" 
                  data-extra-id="${extra.id}">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

function updateExtraQuantity(event) {
  const extraId = event.target.dataset.extraId;
  const price = parseFloat(event.target.dataset.price);
  const quantity = parseFloat(event.target.value) || 1;
  
  console.log(`📊 Updating quantity for extra ${extraId}: ${quantity}`);
  
  // Update total price
  const extraRow = event.target.closest('.process-row');
  const totalDiv = extraRow.querySelector('.total-cost');
  if (totalDiv) {
    const newTotal = price * quantity;
    totalDiv.textContent = formatCurrency(newTotal);
  }
  
  showValidationMessage('Cantidad actualizada correctamente', 'success');
  
  // Trigger recalculation
  triggerRecalculation();
}

// Manual extras functions
function addManualExtra() {
  console.log('💰 Adding manual extra...');
  
  const extrasList = document.getElementById('extras-list');
  const manualExtra = {
    id: 'manual_extra_' + Date.now(),
    name: 'Costo extra nuevo',
    unit_price: 0,
    unit: 'pieza',
    manual: true
  };
  
  console.log('📦 Creating manual extra:', manualExtra);
  
  // Add to formState
  if (!formState.productData.extras) {
    formState.productData.extras = [];
  }
  formState.productData.extras.push({
    id: manualExtra.id,
    name: manualExtra.name,
    unit_price: manualExtra.unit_price,
    quantity: 1,
    manual: true
  });
  
  // Check if this is the first extra - create unified container like material processes
  const existingExtras = extrasList.querySelectorAll('.process-row');
  if (existingExtras.length === 0) {
    // Create unified container for extras (same structure as material processes)
    const unifiedContainer = `
      <div class="material-card processes-unified-container" data-extras="true">
        <div class="material-info">
          <div class="material-details">
            <div class="processes-container">
              <!-- Extras will be added here -->
            </div>
          </div>
        </div>
      </div>
    `;
    extrasList.insertAdjacentHTML('beforeend', unifiedContainer);
    
    // Show container when first extra is added
    const extrasContainer = document.getElementById('extras-container');
    if (extrasContainer) {
      extrasContainer.style.display = 'block';
    }
  }
  
  // Create manual extra row (same structure as material processes)
  const extraRow = createManualExtraRow(manualExtra, 1);
  const processesContainer = extrasList.querySelector('.processes-container');
  processesContainer.insertAdjacentHTML('beforeend', extraRow);
  
  const newItem = processesContainer.lastElementChild;
  const removeBtn = newItem.querySelector('.remove-extra');
  if (removeBtn) {
    removeBtn.addEventListener('click', removeExtra);
  }
  
  bindManualExtraEvents(newItem);
  
  console.log(`✅ Manual extra ${manualExtra.name} added`);
  showValidationMessage(`Extra manual "${manualExtra.name}" agregado correctamente`, 'success');
  triggerRecalculation();
}

function createManualExtraRow(extra, quantity) {
  const totalPrice = extra.unit_price * quantity;
  
  return `
    <div class="process-row" data-extra-id="${extra.id}">
      <div class="row">
        <div class="col-md-7">
          <small class="text-muted">Extra:</small><br>
          <input type="text" class="form-control form-control-sm manual-extra-field" 
                 data-field="name" data-extra-id="${extra.id}" 
                 value="${extra.name}" 
                 placeholder="Nombre del costo extra">
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Unidad:</small><br>
          <strong>${extra.unit || 'Servicio'}</strong>
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Veces:</small><br>
          <input type="number" class="form-control form-control-sm manual-extra-field" 
                 data-field="quantity" data-extra-id="${extra.id}" 
                 value="${quantity}" min="1" step="1" style="text-align: right;">
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Costo:</small><br>
          <input type="number" class="form-control form-control-sm manual-extra-field" 
                 data-field="unit_price" data-extra-id="${extra.id}" 
                 value="${extra.unit_price}" min="0" step="0.01" 
                 placeholder="0.00" style="text-align: right;">
        </div>
        <div class="col-md-1 text-end">
          <small class="text-muted">Total:</small><br>
          <strong class="total-cost">${formatCurrency(totalPrice)}</strong>
        </div>
        <div class="col-md-1 d-flex justify-content-end align-items-center">
          <small class="text-muted">&nbsp;</small><br>
          <button type="button" class="btn btn-sm btn-outline-danger remove-extra" data-extra-id="${extra.id}">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

function bindManualExtraEvents(extraItem) {
  const fields = extraItem.querySelectorAll('.manual-extra-field');
  fields.forEach(field => {
    field.addEventListener('input', handleManualExtraFieldChange);
    field.addEventListener('change', handleManualExtraFieldChange);
  });
}

function handleManualExtraFieldChange(event) {
  const extraId = event.target.dataset.extraId;
  const fieldName = event.target.dataset.field;
  const value = event.target.value;
  
  console.log(`🔄 Manual extra field changed: ${fieldName} = ${value} for extra ${extraId}`);
  
  // Update the extra data in formState
  if (!formState.productData.extras) {
    formState.productData.extras = [];
  }
  
  let extraIndex = formState.productData.extras.findIndex(extra => extra.id == extraId);
  if (extraIndex === -1) {
    // Create new extra entry
    formState.productData.extras.push({
      id: extraId,
      name: 'Costo extra nuevo',
      unit_price: 0,
      quantity: 1,
      manual: true
    });
    extraIndex = formState.productData.extras.length - 1;
  }
  
  // Update the field
  if (fieldName === 'name') {
    formState.productData.extras[extraIndex].name = value;
  } else if (fieldName === 'unit_price') {
    formState.productData.extras[extraIndex].unit_price = parseFloat(value) || 0;
  } else if (fieldName === 'quantity') {
    formState.productData.extras[extraIndex].quantity = parseFloat(value) || 1;
  }
  
  // Recalculate the extra
  recalculateManualExtra(extraId);
}

function recalculateManualExtra(extraId) {
  console.log(`🧮 Recalculating manual extra ${extraId}`);
  
  const extraCard = document.querySelector(`[data-extra-id="${extraId}"]`);
  if (!extraCard) {
    console.error(`❌ Extra card not found for ID: ${extraId}`);
    return;
  }
  
  // Get current values from formState
  const extraData = formState.productData.extras.find(extra => extra.id == extraId);
  if (!extraData) {
    console.error(`❌ Extra data not found in formState for ID: ${extraId}`);
    return;
  }
  
  const unitPrice = extraData.unit_price || 0;
  const quantity = extraData.quantity || 1;
  const totalPrice = unitPrice * quantity;
  
  console.log(`📊 Manual extra calculation: ${unitPrice} × ${quantity} = ${totalPrice}`);
  
  // Update display
  updateManualExtraCardDisplay(extraCard, { totalPrice });
  
  // Trigger final recalculation to update totals
  triggerRecalculation();
}

function updateManualExtraCardDisplay(card, calculatedData) {
  const totalElement = card.querySelector('.total-cost');
  if (totalElement) {
    totalElement.textContent = formatCurrency(calculatedData.totalPrice);
    console.log(`✅ Manual extra total updated to ${formatCurrency(calculatedData.totalPrice)}`);
  }
}

function removeExtra(event) {
  const extraId = event.target.dataset.extraId || event.target.closest('button').dataset.extraId;
  const extraRow = event.target.closest('.process-row');
  
  console.log(`🗑️ Removing extra ${extraId}`);
  
  if (extraRow) {
    extraRow.remove();
    
    // Check if this was the last extra - remove unified container like material processes
    const extrasList = document.getElementById('extras-list');
    const remainingExtras = extrasList.querySelectorAll('.process-row');
    
    console.log(`🔍 Remaining extras: ${remainingExtras?.length || 0}`);
    
    if (remainingExtras && remainingExtras.length === 0) {
      // Remove the unified container
      const unifiedContainer = extrasList.querySelector('.processes-unified-container');
      console.log(`🗑️ Removing unified container:`, unifiedContainer);
      if (unifiedContainer) {
        unifiedContainer.remove();
        console.log(`✅ Unified container removed successfully`);
      }
      
      // Hide main container if no extras remain
      const extrasContainer = document.getElementById('extras-container');
      if (extrasContainer) {
        extrasContainer.style.display = 'none';
      }
    }
    
    showValidationMessage('Extra eliminado correctamente', 'success');
    
    // Trigger recalculation
    triggerRecalculation();
  }
}

// ===== CALCULATION FUNCTIONS =====

function calculateMaterialsCost() {
  
  const materialCards = document.querySelectorAll('.material-card[data-material-id]');
  let total = 0;
  
  materialCards.forEach(card => {
    const materialTotalCostElement = card.querySelector('.material-total-cost');
    if (materialTotalCostElement) {
      const costText = materialTotalCostElement.textContent.replace(/[$,]/g, '');
      const cost = parseFloat(costText) || 0;
      total += cost;
    }
  });

  return total;
}

function calculateProcessesCost() {
  
  let appliedProcessesTotal = 0;
  let globalProcessesTotal = 0;
  
  // Calculate material processes (applied processes) - these are inside material cards
  // Use a more specific selector to avoid counting processes-unified-container
  const materialCards = document.querySelectorAll('.material-card[data-material-id]:not(.processes-unified-container)');
  console.log(`🔍 Found ${materialCards.length} material cards for process calculation`);
  
  materialCards.forEach((card, cardIndex) => {
    const materialId = card.dataset.materialId;
    const processRows = card.querySelectorAll('.process-row[data-material-id]');
    console.log(`🔍 Material ${materialId} (card ${cardIndex}): Found ${processRows.length} process rows`);
    
    processRows.forEach((row, rowIndex) => {
      const processId = row.dataset.processId;
      const totalCostElement = row.querySelector('.total-cost');
      if (totalCostElement) {
        const costText = totalCostElement.textContent.replace(/[$,]/g, '');
        const cost = parseFloat(costText) || 0;
        appliedProcessesTotal += cost;
        console.log(`  🔧 Applied process cost (Material ${materialId}, Process ${processId}, Row ${rowIndex}): ${formatCurrency(cost)}`);
      }
    });
  });
  
  // Calculate global processes - these are specifically in the global-processes-list container
  // and do NOT have data-material-id (that's how we distinguish them from material processes)
  const globalProcessesList = document.getElementById('global-processes-list');
  if (globalProcessesList) {
    const globalProcessRows = globalProcessesList.querySelectorAll('.process-row[data-process-id][data-side]:not([data-material-id])');
    globalProcessRows.forEach(row => {
      const totalCostElement = row.querySelector('.total-cost');
      if (totalCostElement) {
        const costText = totalCostElement.textContent.replace(/[$,]/g, '');
        const cost = parseFloat(costText) || 0;
        globalProcessesTotal += cost;
        console.log(`  🌍 Global process cost: ${formatCurrency(cost)}`);
      }
    });
  }
  
  const totalProcessesCost = appliedProcessesTotal + globalProcessesTotal;
  
  return {
    appliedProcesses: appliedProcessesTotal,
    globalProcesses: globalProcessesTotal,
    total: totalProcessesCost
  };
}

function calculateExtrasCost() {
  
  const extraRows = document.querySelectorAll('.process-row[data-extra-id]');
  let total = 0;
  
  extraRows.forEach(row => {
    const totalCostElement = row.querySelector('.total-cost');
    if (totalCostElement) {
      const costText = totalCostElement.textContent.replace(/[$,]/g, '');
      const cost = parseFloat(costText) || 0;
      total += cost;
    }
  });
  
  return total;
}

function calculateFinalTotals() {
  
  // Get individual costs
  const materialsCost = calculateMaterialsCost();
  const processesData = calculateProcessesCost();
  const extrasCost = calculateExtrasCost();
  
  // Calculate subtotal
  const subtotal = materialsCost + processesData.total + extrasCost;
  
  // Get product quantity
  const quantityInput = document.querySelector('[name="product[quantity]"]');
  const quantity = parseFloat(quantityInput?.value) || 1;
  
  // Get waste percentage from sidebar input (default 2%)
  const wastePercentageInput = document.getElementById('sidebar-waste-percentage-input');
  const wastePercentage = parseFloat(wastePercentageInput?.value) || 2;
  const wasteValue = subtotal * (wastePercentage / 100);
  
  // Calculate subtotal with waste
  const subtotalWithWaste = subtotal + wasteValue;
  
  // Calculate cost per piece before margin
  const priceBeforeMargin = subtotalWithWaste / quantity;
  
  // Get margin percentage from sidebar input (default 5%)
  const marginPercentageInput = document.getElementById('sidebar-margin-percentage-input');
  const marginPercentage = parseFloat(marginPercentageInput?.value) || 5;
  const marginValue = subtotalWithWaste * (marginPercentage / 100);
  
  // Calculate final totals
  const totalPrice = subtotalWithWaste + marginValue;
  const finalPricePerPiece = totalPrice / quantity;
  
  // Update the UI
  updateFinalCalculationDisplay({
    materialsCost,
    appliedProcessesCost: processesData.appliedProcesses,
    globalProcessesCost: processesData.globalProcesses,
    extrasCost,
    subtotal,
    wastePercentage,
    wasteValue,
    subtotalWithWaste,
    priceBeforeMargin,
    marginPercentage,
    marginValue,
    totalPrice,
    finalPricePerPiece
  });

  // Update sidebar calculation
  updateSidebarCalculation({
    materialsCost,
    appliedProcessesCost: processesData.appliedProcesses,
    globalProcessesCost: processesData.globalProcesses,
    extrasCost,
    subtotal,
    wastePercentage,
    wasteValue,
    subtotalWithWaste,
    priceBeforeMargin,
    marginPercentage,
    marginValue,
    totalPrice,
    finalPricePerPiece
  });

  // Update section totals
  updateSectionTotals({
    materialsCost,
    appliedProcessesCost: processesData.appliedProcesses,
    globalProcessesCost: processesData.globalProcesses,
    extrasCost
  });
  
  return {
    materialsCost,
    appliedProcessesCost: processesData.appliedProcesses,
    globalProcessesCost: processesData.globalProcesses,
    extrasCost,
    subtotal,
    wastePercentage,
    wasteValue,
    subtotalWithWaste,
    priceBeforeMargin,
    marginPercentage,
    marginValue,
    totalPrice,
    finalPricePerPiece
  };
}

function updateFinalCalculationDisplay(calculations) {
  
  // Update each field with correct IDs
  const fields = {
    'final-materials-cost': calculations.materialsCost,
    'final-applied-processes-cost': calculations.appliedProcessesCost,
    'final-global-processes-cost': calculations.globalProcessesCost,
    'final-extras-cost': calculations.extrasCost,
    'final-subtotal': calculations.subtotal,
    'final-waste': calculations.wasteValue,
    'final-subtotal-with-waste': calculations.subtotalWithWaste,
    'final-price-before-margin': calculations.priceBeforeMargin,
    'final-margin': calculations.marginValue,
    'final-total-price': calculations.totalPrice,
    'final-price-per-piece': calculations.finalPricePerPiece
  };
  
  Object.entries(fields).forEach(([fieldId, value]) => {
    const element = document.getElementById(fieldId);
    if (element) {
      element.textContent = formatCurrency(value);
    }
  });
}

// Update sidebar calculation display
function updateSidebarCalculation(calculations) {
  console.log('📊 Updating sidebar calculation:', calculations);
  
  // Update each field with correct IDs for sidebar
  const sidebarFields = {
    'sidebar-final-materials-cost': calculations.materialsCost,
    'sidebar-final-applied-processes-cost': calculations.appliedProcessesCost,
    'sidebar-final-global-processes-cost': calculations.globalProcessesCost,
    'sidebar-final-extras-cost': calculations.extrasCost,
    'sidebar-final-subtotal': calculations.subtotal,
    'sidebar-final-waste': calculations.wasteValue,
    'sidebar-final-subtotal-with-waste': calculations.subtotalWithWaste,
    'sidebar-final-price-before-margin': calculations.priceBeforeMargin,
    'sidebar-final-margin': calculations.marginValue,
    'sidebar-final-total-price': calculations.totalPrice,
    'sidebar-final-price-per-piece': calculations.finalPricePerPiece
  };
  
  Object.entries(sidebarFields).forEach(([fieldId, value]) => {
    const element = document.getElementById(fieldId);
    if (element) {
      element.textContent = formatCurrency(value);
      console.log(`✅ Updated sidebar ${fieldId}: ${formatCurrency(value)}`);
    } else {
      console.warn(`⚠️ Sidebar element not found: ${fieldId}`);
    }
  });
}

// Update section totals display
function updateSectionTotals(totals) {
  console.log('📊 Updating section totals:', totals);
  
  // Update each section total (section 5 removed, only sections 2-4)
  const sectionFields = {
    'section-materials-total': totals.materialsCost + totals.appliedProcessesCost, // Materials + their processes
    'section-global-processes-total': totals.globalProcessesCost,
    'section-extras-total': totals.extrasCost
  };
  
  Object.entries(sectionFields).forEach(([fieldId, value]) => {
    const element = document.getElementById(fieldId);
    if (element) {
      element.textContent = formatCurrency(value);
      console.log(`✅ Updated ${fieldId}: ${formatCurrency(value)}`);
    } else {
      console.warn(`⚠️ Section total element not found: ${fieldId}`);
    }
  });
}

// Auto-calculate when materials, processes, or extras change
function triggerRecalculation() {
  setTimeout(() => {
    calculateFinalTotals();
  }, 100); // Small delay to ensure DOM is updated
}

// Bind percentage input events
function bindPercentageInputEvents() {
  const sidebarWasteInput = document.getElementById('sidebar-waste-percentage-input');
  const sidebarMarginInput = document.getElementById('sidebar-margin-percentage-input');
  
  // Bind events for sidebar inputs (main form section removed)
  if (sidebarWasteInput) {
    sidebarWasteInput.addEventListener('change', triggerRecalculation);
    sidebarWasteInput.addEventListener('input', triggerRecalculation);
  }
  
  if (sidebarMarginInput) {
    sidebarMarginInput.addEventListener('change', triggerRecalculation);
    sidebarMarginInput.addEventListener('input', triggerRecalculation);
  }
}

// All V3 functions loaded successfully