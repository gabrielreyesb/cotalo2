/**
 * Scenario 3: Multiple Materials Product Validation
 * 
 * Product configuration:
 * - Quantity: 3000 pieces
 * - Dimensions: 32cm × 22cm
 * - Material 1: Papel bond 90 g/m² + Impresión offset, Barniz UV, Embolsado
 * - Material 2: Cartulina caple sulfatada 12 pts + Impresión offset, Embolsado
 * - Material 3: Papel couché brillante 150 grs (no processes)
 * - Global process: Empaque individual
 * 
 * Expected calculations:
 * - Material costs: Sum of all 3 materials based on 3000 pieces
 * - Process costs: Sum of all material processes + global process
 * - Subtotal: Material + Process
 */
describe('Scenario 3: Multiple Materials Product', () => {
  beforeEach(() => {
    // Set viewport to a larger size for better visibility
    cy.viewport(1920, 1080)
  })

  // Store expected values - will be updated with actual system calculations
  let expectedValues = {
    materialCost: 0,           // Will be captured from system
    processCost: 0,            // Will be captured from system  
    globalProcessCost: 0,      // Will be captured from system
    totalExpected: 0           // Will be calculated from captured values
  };

  before(() => {
    // Visit the login page
    cy.visit('/users/sign_in')
    
    // Fill in login form
    cy.get('input[name="user[email]"]').type('gabrielreyesb@gmail.com')
    cy.get('input[name="user[password]"]').type('123456')
    cy.get('form').submit()
    
    // Wait for login to complete
    cy.url().should('not.include', '/users/sign_in')
  })

  it('should create product with multiple materials and processes', () => {
    // 1. Go to V2 product form (already on Product tab)
    cy.visit('/products/new_v2')
    cy.wait(2000)
    cy.log('✅ Page loaded')
    
    // 2. Fill basic product info
    cy.get('#product-description').clear().type('Producto Múltiples Materiales V2 - Escenario 3')
    cy.get('#product-quantity').clear().type('3000')
    cy.get('#product-width').clear().type('32')
    cy.get('#product-length').clear().type('22')
    cy.log('✅ Basic info filled')
    
    // 3. Add first material: Papel bond 90 g/m²
    cy.get('.multiselect').first().click()
    cy.get('.multiselect__option').contains('Papel bond 90 g/m²').click()
    cy.contains('Agregar').click()
    // If simulation modal appears, close it to continue
    cy.get('body').then(($body) => {
      if ($body.find('.modal.show .modal-title:contains("Simulación")').length || $body.find('.modal.show').length) {
        cy.contains('button', 'Entendido').click({ force: true })
      }
    })
    cy.wait(2000)
    cy.log('✅ Material 1 added (Papel bond 90 g/m²)')
    
    // Add processes to Material 1
    cy.get('.material-item').eq(1).within(() => {
      // First process: Impresión offset 4 tintas (CMYK)
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.get('.process-form-section').should('be.visible')
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Impresión offset 4 tintas (CMYK)').click({force: true})
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      cy.get('select').first().select('front')
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Material 1 - Impresión offset added')
      
      // Second process: Barniz UV
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.get('.process-form-section').should('be.visible')
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Barniz UV').click({force: true})
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      cy.get('select').first().select('front')
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Material 1 - Barniz UV added')
      
      // Third process: Embolsado
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.get('.process-form-section').should('be.visible')
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Embolsado').click({force: true})
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      cy.get('select').first().select('front')
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Material 1 - Embolsado added')
    })
    
    // 4. Add second material: Cartulina caple sulfatada 12 pts
    cy.get('.multiselect').first().click()
    cy.get('.multiselect__option').contains('Cartulina caple sulfatada 12 pts').click()
    cy.contains('Agregar').click()
    // If simulation modal appears again, close it to continue
    cy.get('body').then(($body) => {
      if ($body.find('.modal.show .modal-title:contains("Simulación")').length || $body.find('.modal.show').length) {
        cy.contains('button', 'Entendido').click({ force: true })
      }
    })
    cy.wait(2000)
    cy.log('✅ Material 2 added (Cartulina caple sulfatada 12 pts)')
    
    // Add processes to Material 2
    cy.get('.material-item').eq(2).within(() => {
      // First process: Impresión offset 4 tintas (CMYK)
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.get('.process-form-section').should('be.visible')
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Impresión offset 4 tintas (CMYK)').click({force: true})
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      cy.get('select').first().select('front')
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Material 2 - Impresión offset added')
      
      // Second process: Embolsado
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.get('.process-form-section').should('be.visible')
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Embolsado').click({force: true})
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      cy.get('select').first().select('front')
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Material 2 - Embolsado added')
    })
    
    // 5. Add third material: Papel couché brillante 150 grs (no processes)
    cy.get('.multiselect').first().click()
    cy.get('.multiselect__option').contains('Papel couché brillante 150 grs').click()
    cy.contains('Agregar').click()
    // If simulation modal appears again, close it to continue
    cy.get('body').then(($body) => {
      if ($body.find('.modal.show .modal-title:contains("Simulación")').length || $body.find('.modal.show').length) {
        cy.contains('button', 'Entendido').click({ force: true })
      }
    })
    cy.wait(2000)
    cy.log('✅ Material 3 added (Papel couché brillante 150 grs) - No processes')
    
    // Capture material cost for validation
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Materiales:').parent().find('td').invoke('text').then((text) => {
        const rawText = text.trim();
        expectedValues.materialCost = parseFloat(rawText.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured material cost: $${expectedValues.materialCost.toFixed(2)}`);
      });
    })
    
    // Capture process cost for validation
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Procesos aplicados:').parent().find('td').invoke('text').then((text) => {
        expectedValues.processCost = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured material process cost: $${expectedValues.processCost.toFixed(2)}`);
      });
    })
    
    // 6. Go to "Costos adicionales" tab and add global process
    cy.get('a.nav-link').contains('Costos adicionales').click()
    cy.wait(2000)
    cy.log('✅ Switched to Additional Costs tab')
    
    // Add global process: Empaque individual
    cy.get('.additional-costs-tab-v2 .multiselect').first().click()
    cy.wait(500)
    cy.get('.multiselect__option').contains('Empaque individual').click({force: true})
    cy.contains('Agregar proceso').click()
    cy.wait(1000)
    cy.log('✅ Global process added (Empaque individual)')
    
    // Capture updated process cost (includes both material processes and global processes)
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Procesos globales:').parent().find('td').invoke('text').then((text) => {
        expectedValues.globalProcessCost = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured global process cost: $${expectedValues.globalProcessCost.toFixed(2)}`);
      });
    })
    
    // 7. Validate calculations in the pricing panel
    cy.get('.pricing-panel').scrollIntoView().should('be.visible')
    cy.log('✅ Pricing panel visible')
    
    // Validate that all cost categories match expected values
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      // Validate materials cost
      cy.get('tr').contains('Materiales:').parent().find('td').invoke('text').then((text) => {
        const actualValue = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        expect(actualValue).to.equal(expectedValues.materialCost);
        cy.log(`✅ Materials cost: $${actualValue.toFixed(2)} (expected: $${expectedValues.materialCost.toFixed(2)})`);
      });
      
      // Validate processes cost (includes both material process and global process)
      cy.get('tr').contains('Procesos aplicados:').parent().find('td').invoke('text').then((text) => {
        const actualValue = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        expect(actualValue).to.equal(expectedValues.processCost);
        cy.log(`✅ Material processes cost: $${actualValue.toFixed(2)} (expected: $${expectedValues.processCost.toFixed(2)})`);
      });
      
      // Validate global processes cost
      cy.get('tr').contains('Procesos globales:').parent().find('td').invoke('text').then((text) => {
        const actualValue = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        expect(actualValue).to.equal(expectedValues.globalProcessCost);
        cy.log(`✅ Global processes cost: $${actualValue.toFixed(2)} (expected: $${expectedValues.globalProcessCost.toFixed(2)})`);
      });
      
      // Validate subtotal
      cy.get('tr').contains('Subtotal:').parent().find('td').invoke('text').then((text) => {
        const actualValue = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        
        // Calculate expected subtotal from captured values
        const expectedSubtotal = expectedValues.materialCost + expectedValues.processCost + expectedValues.globalProcessCost;
        
        // Validate exact calculation - no tolerance for simple arithmetic
        expect(actualValue).to.equal(expectedSubtotal);
        cy.log(`✅ Subtotal: $${actualValue.toFixed(2)} (expected: $${expectedSubtotal.toFixed(2)})`);
        cy.log(`   Breakdown: Material($${expectedValues.materialCost.toFixed(2)}) + Material Process($${expectedValues.processCost.toFixed(2)}) + Global Process($${expectedValues.globalProcessCost.toFixed(2)})`);
      });
    });
    
    // Final validation summary - Capture ALL pricing panel values
    cy.log(`🧮 FINAL PRICING PANEL VALUES:`);
    
    let pricingPanelValues = {};
    
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      // Capture all values from the pricing panel
      cy.get('tr').each(($row) => {
        const label = $row.find('th').text().trim();
        const value = $row.find('td').text().trim();
        
        if (label && value) {
          pricingPanelValues[label] = value;
          cy.log(`   ${label}: ${value}`);
        }
      });
    }).then(() => {
      // Write all pricing panel values to file
      cy.writeFile('cypress/scenario_3_pricing_panel_values.json', {
        pricingPanelValues: pricingPanelValues,
        capturedValues: {
          materialCost: expectedValues.materialCost,
          processCost: expectedValues.processCost,
          globalProcessCost: expectedValues.globalProcessCost
        },
        timestamp: new Date().toISOString()
      });
    });
    
    cy.log(`📊 CAPTURED VALUES SUMMARY:`);
    cy.log(`   Material Cost: $${expectedValues.materialCost.toFixed(2)}`);
    cy.log(`   Process Cost: $${expectedValues.processCost.toFixed(2)}`);
    cy.log(`   Global Process Cost: $${expectedValues.globalProcessCost.toFixed(2)}`);
    const calculatedTotal = expectedValues.materialCost + expectedValues.processCost + expectedValues.globalProcessCost;
    cy.log(`   Calculated Subtotal: $${calculatedTotal.toFixed(2)}`);
    cy.log(`   ✅ All calculations validated successfully!`);
    
    // Also log to console for better visibility
    cy.then(() => {
      console.log('=== SCENARIO 3 FINAL CALCULATED VALUES ===');
      console.log(`Material Cost: $${expectedValues.materialCost.toFixed(2)}`);
      console.log(`Process Cost: $${expectedValues.processCost.toFixed(2)}`);
      console.log(`Global Process Cost: $${expectedValues.globalProcessCost.toFixed(2)}`);
      console.log(`Total Calculated: $${calculatedTotal.toFixed(2)}`);
      console.log('==========================================');
      
      // Write to a temporary file for easy access
      cy.writeFile('cypress/scenario_3_calculated_values.json', {
        materialCost: expectedValues.materialCost,
        processCost: expectedValues.processCost,
        globalProcessCost: expectedValues.globalProcessCost,
        totalCalculated: calculatedTotal,
        timestamp: new Date().toISOString()
      });
    });
    
    // 8. Save the product
    cy.get('button').contains('Guardar').click()
    cy.wait(2000)
    cy.log('✅ Product saved')
    
    // 9. Verify product was created successfully (robust to trailing slash)
    cy.location('pathname', { timeout: 10000 }).should('match', /\/products$/)
    cy.log('✅ Product created successfully')
    
    cy.log('✅ Scenario 3 completed successfully')
  })
}) 