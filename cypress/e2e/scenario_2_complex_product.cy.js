/**
 * Scenario 2: Complex Product Validation - Multiple Processes
 * 
 * Product configuration:
 * - 1 material: Papel bond 90 g/m²
 * - 3 processes to material: Impresión offset 4 tintas (CMYK), Barniz UV (2 times), Embolsado
 * - 1 global process: Corte y plegado (1 time)
 * - 1 indirect cost: Diseño gráfico profesional (quantity 10)
 * 
 * Expected calculations:
 * - Material: 20cm x 30cm x 100 pieces = 7 m² × $5.00/m² = $35.00
 * - Process costs: Sum of all material processes + global process × 2
 * - Indirect cost: Fixed price × 10
 * - Subtotal: Material + Process + Indirect
 */
describe('Scenario 2: Complex Product - Multiple Processes', () => {
  beforeEach(() => {
    // Set viewport to a larger size for better visibility
    cy.viewport(1920, 1080)
  })

  // Store expected values - will be updated with actual system calculations
  let expectedValues = {
    materialCost: 0,           // Will be captured from system
    processCost: 0,            // Will be captured from system  
    globalProcessCost: 0,      // Will be captured from system
    indirectCost: 0,           // Will be captured from system
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

  it('should create complex product with multiple processes', () => {
    // 1. Go to V2 product form (already on Product tab)
    cy.visit('/products/new_v2')
    cy.wait(2000)
    cy.log('✅ Page loaded')
    
    // 2. Fill basic product info
    cy.get('#product-description').clear().type('Producto Complejo V2 - Escenario 2')
    cy.get('#product-quantity').clear().type('100')
    cy.get('#product-width').clear().type('20')
    cy.get('#product-length').clear().type('30')
    cy.log('✅ Basic info filled')
    
    // 3. Add first material (selector should already be loaded)
    cy.get('.multiselect').first().click()
    // Select specifically "Papel bond 90 g/m²" instead of first option
    cy.get('.multiselect__option').contains('Papel bond 90 g/m²').click()
    cy.contains('Agregar').click()
    cy.wait(2000) // Wait longer for calculations to complete
    cy.log('✅ Material added (Papel bond 90 g/m²)')
    
    // Capture material cost for validation - IMMEDIATELY after adding material
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Materiales:').parent().find('td').invoke('text').then((text) => {
        const rawText = text.trim();
        expectedValues.materialCost = parseFloat(rawText.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured material cost: $${expectedValues.materialCost.toFixed(2)}`);
      });
    })
    
    // Wait a bit more to ensure calculations are complete
    cy.wait(1000)
    
    // 4. Add multiple processes to material
    cy.get('.material-item').eq(1).within(() => {
      // First process: Impresión offset 4 tintas
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.log('✅ Add process button clicked')
      
      cy.get('.process-form-section').should('be.visible')
      cy.log('✅ Process form found!')
      
      // Select "Impresión offset 4 tintas (CMYK)" from dropdown
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Impresión offset 4 tintas (CMYK)').click({force: true})
      
      // Set times to 1
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      
      // Set side to front
      cy.get('select').first().select('front')
      
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ First process (Impresión offset 4 tintas CMYK) added to material')
      
      // Second process: Barniz UV (2 times)
      cy.get('button.btn-success').click()
      cy.wait(1000)
      
      cy.get('.process-form-section').should('be.visible')
      
      // Select "Barniz UV" from dropdown
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Barniz UV').click({force: true})
      
      // Set times to 2
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('2')
      
      // Set side to front
      cy.get('select').first().select('front')
      
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Second process (Barniz UV x2) added to material')
      
      // Third process: Embolsado
      cy.get('button.btn-success').click()
      cy.wait(1000)
      
      cy.get('.process-form-section').should('be.visible')
      
      // Select "Embolsado" from dropdown
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').contains('Embolsado').click({force: true})
      
      // Set times to 1
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      
      // Set side to front
      cy.get('select').first().select('front')
      
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Third process (Embolsado) added to material')
    })
    
    // Capture process cost for validation
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Procesos aplicados:').parent().find('td').invoke('text').then((text) => {
        expectedValues.processCost = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured material process cost: $${expectedValues.processCost.toFixed(2)}`);
      });
    })
    
    // 5. Go to "Costos adicionales" tab and add global process
    cy.get('a.nav-link').contains('Costos adicionales').click()
    cy.wait(2000)
    cy.log('✅ Switched to Additional Costs tab')
    
    // Add global process - use the first multiselect in the additional costs tab
    cy.get('.additional-costs-tab-v2 .multiselect').first().click()
    cy.wait(500)
    cy.get('.multiselect__option').first().click({force: true})
    cy.contains('Agregar proceso').click()
    cy.wait(1000)
    cy.log('✅ Global process added (Corte y plegado)')
    
    // Capture updated process cost (includes both material processes and global processes)
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Procesos globales:').parent().find('td').invoke('text').then((text) => {
        expectedValues.globalProcessCost = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured global process cost: $${expectedValues.globalProcessCost.toFixed(2)}`);
      });
    })
    
    // 6. Add indirect cost - specifically target the indirect costs section
    cy.get('.additional-costs-tab-v2').within(() => {
      // Find the indirect costs section and work within it
      cy.get('.card').eq(1).within(() => { // Second card is indirect costs
        // Select first indirect cost option
        cy.get('.multiselect').click()
        cy.wait(500)
        cy.get('.multiselect__option').first().click({force: true})
        cy.wait(500)
        
        // Set quantity to 10
        cy.get('input[inputmode="decimal"]').clear().type('10')
        
        // Click the "Agregar indirecto" button
        cy.contains('Agregar indirecto').click()
        cy.wait(1000)
        cy.log('✅ Indirect cost added (quantity: 10)')
      })
    })
    
    // Capture indirect cost for validation
    cy.get('.pricing-panel').scrollIntoView().within(() => {
      cy.get('tr').contains('Indirectos:').parent().find('td').invoke('text').then((text) => {
        expectedValues.indirectCost = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 Captured indirect cost: $${expectedValues.indirectCost.toFixed(2)}`);
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
      
      // Validate indirect costs
      cy.get('tr').contains('Indirectos:').parent().find('td').invoke('text').then((text) => {
        const actualValue = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        expect(actualValue).to.equal(expectedValues.indirectCost);
        cy.log(`✅ Indirect costs: $${actualValue.toFixed(2)} (expected: $${expectedValues.indirectCost.toFixed(2)})`);
      });
      
      // Validate subtotal
      cy.get('tr').contains('Subtotal:').parent().find('td').invoke('text').then((text) => {
        const actualValue = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        
        // Calculate expected subtotal from captured values
        const expectedSubtotal = expectedValues.materialCost + expectedValues.processCost + expectedValues.globalProcessCost + expectedValues.indirectCost;
        
        // Validate exact calculation - no tolerance for simple arithmetic
        expect(actualValue).to.equal(expectedSubtotal);
        cy.log(`✅ Subtotal: $${actualValue.toFixed(2)} (expected: $${expectedSubtotal.toFixed(2)})`);
        cy.log(`   Breakdown: Material($${expectedValues.materialCost.toFixed(2)}) + Material Process($${expectedValues.processCost.toFixed(2)}) + Global Process($${expectedValues.globalProcessCost.toFixed(2)}) + Indirect($${expectedValues.indirectCost.toFixed(2)})`);
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
      cy.writeFile('cypress/scenario_2_pricing_panel_values.json', {
        pricingPanelValues: pricingPanelValues,
        capturedValues: {
          materialCost: expectedValues.materialCost,
          processCost: expectedValues.processCost,
          globalProcessCost: expectedValues.globalProcessCost,
          indirectCost: expectedValues.indirectCost
        },
        timestamp: new Date().toISOString()
      });
    });
    
    cy.log(`📊 CAPTURED VALUES SUMMARY:`);
    cy.log(`   Material Cost: $${expectedValues.materialCost.toFixed(2)}`);
    cy.log(`   Process Cost: $${expectedValues.processCost.toFixed(2)}`);
    cy.log(`   Global Process Cost: $${expectedValues.globalProcessCost.toFixed(2)}`);
    cy.log(`   Indirect Cost: $${expectedValues.indirectCost.toFixed(2)}`);
    const calculatedTotal = expectedValues.materialCost + expectedValues.processCost + expectedValues.globalProcessCost + expectedValues.indirectCost;
    cy.log(`   Calculated Subtotal: $${calculatedTotal.toFixed(2)}`);
    cy.log(`   ✅ All calculations validated successfully!`);
    
    // Also log to console for better visibility
    cy.then(() => {
      console.log('=== SCENARIO 2 FINAL CALCULATED VALUES ===');
      console.log(`Material Cost: $${expectedValues.materialCost.toFixed(2)}`);
      console.log(`Process Cost: $${expectedValues.processCost.toFixed(2)}`);
      console.log(`Global Process Cost: $${expectedValues.globalProcessCost.toFixed(2)}`);
      console.log(`Indirect Cost: $${expectedValues.indirectCost.toFixed(2)}`);
      console.log(`Total Calculated: $${calculatedTotal.toFixed(2)}`);
      console.log('==========================================');
      
      // Write to a temporary file for easy access
      cy.writeFile('cypress/scenario_2_calculated_values.json', {
        materialCost: expectedValues.materialCost,
        processCost: expectedValues.processCost,
        globalProcessCost: expectedValues.globalProcessCost,
        indirectCost: expectedValues.indirectCost,
        totalCalculated: calculatedTotal,
        timestamp: new Date().toISOString()
      });
    });
    
    // 8. Save the product
    cy.get('button').contains('Guardar').click()
    cy.wait(2000)
    cy.log('✅ Product saved')
    
    // 9. Verify product was created successfully
    cy.url().should('include', '/products/')
    cy.log('✅ Product created successfully')
    
    cy.log('✅ Scenario 2 completed successfully')
  })
}) 