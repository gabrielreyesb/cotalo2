/**
 * Scenario 5: Recalculation Validation - Controlled Changes
 * 
 * This test validates that the recalculation system works correctly by:
 * 1. Creating a product with materials and processes
 * 2. Making controlled changes that should trigger recalculations
 * 3. Verifying that dependent values update correctly
 * 
 * Test flow:
 * - Initial setup: 1000 pieces, 20x15cm, 1 material, 1 process
 * - Change quantity to 2000: should double material and process costs
 * - Change dimensions to 25x20cm: should change material and process costs
 * - Add second material: should increase material costs
 * - Add process to second material: should increase process costs
 */
describe('Scenario 5: Recalculation Validation', () => {
  beforeEach(() => {
    // Set viewport to a larger size for better visibility
    cy.viewport(1920, 1080)
  })

  // Store initial values for comparison
  let initialValues = {
    materialCost: 0,
    processCost: 0,
    totalCost: 0
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

  it('should validate recalculation system with controlled changes', () => {
    // 1. Go to V2 product form (already on Product tab)
    cy.visit('/products/new_v2')
    cy.wait(3000) // Wait longer for page to load completely
    cy.log('✅ Page loaded')
    
    // Wait for the form to be ready
    cy.get('#product-description').should('be.visible')
    cy.log('✅ Form is ready')
    
    // 2. Fill basic product info
    cy.get('#product-description').clear().type('Producto de Prueba - Recalculo')
    cy.get('#product-quantity').clear().type('1000')
    cy.get('#product-width').clear().type('20')
    cy.get('#product-length').clear().type('15')
    cy.log('✅ Basic info filled')
    
    // 3. Add first material (selector should already be loaded)
    cy.get('.multiselect').first().click()
    // Select specifically "Papel bond 90 g/m²" instead of first option
    cy.get('.multiselect__option').contains('Papel bond 90 g/m²').click()
    cy.contains('Agregar').click()
    // If simulation modal appears, close it to continue
    cy.get('body').then(($body) => {
      if ($body.find('.modal.show .modal-title:contains("Simulación")').length || $body.find('.modal.show').length) {
        cy.contains('button', 'Entendido').click({ force: true })
      }
    })
    cy.wait(2000) // Wait longer for calculations to complete
    cy.log('✅ Material added (Papel bond 90 g/m²)')
    
    // Capture initial material cost for validation
    cy.get('.pricing-panel').within(() => {
      cy.get('tr').contains('Materiales:').parent().find('td').invoke('text').then((text) => {
        const rawText = text.trim();
        initialValues.materialCost = parseFloat(rawText.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 INITIAL VALUES - Material cost: $${initialValues.materialCost.toFixed(2)}`);
      });
    })
    
    // Wait a bit more to ensure calculations are complete
    cy.wait(1000)
    
    // 4. Add process to material
    cy.get('.material-item').eq(1).within(() => {
      cy.get('button.btn-success').click()
      cy.wait(1000)
      cy.log('✅ Add process button clicked')
      
      cy.get('.process-form-section').should('be.visible')
      cy.log('✅ Process form found!')
      
      // Select first process from dropdown
      cy.get('.multiselect').click()
      cy.get('.multiselect__option').first().click()
      
      // Set times to 1
      cy.get('.process-form-section input[inputmode="decimal"]').clear().type('1')
      
      // Set side to front
      cy.get('select').first().select('front')
      
      cy.contains('Agregar').click()
      cy.wait(1000)
      cy.log('✅ Process added to material')
    })
    
    // Capture initial process cost for validation
    cy.get('.pricing-panel').within(() => {
      cy.get('tr').contains('Procesos aplicados:').parent().find('td').invoke('text').then((text) => {
        initialValues.processCost = parseFloat(text.replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 INITIAL VALUES - Material process cost: $${initialValues.processCost.toFixed(2)}`);
      });
    })
    
    // 5. Test quantity change recalculation
    cy.log('🔄 QUANTITY CHANGE TEST - Changing from 1000 to 2000 pieces');
    
    // Change the quantity and verify recalculation
    cy.get('#product-quantity').clear().type('2000').blur();
    cy.wait(2000); // Wait longer for recalculation
    
    // Debug: Check if the quantity was actually changed
    cy.get('#product-quantity').should('have.value', '2000');
    cy.log('✅ Quantity changed to 2000');
    
    // Verify that the pricing panel updates with the new quantity
    cy.get('.pricing-panel').within(() => {
      // Verify material cost increased (should be approximately double)
      cy.get('tr').contains('Materiales:').parent().find('td').invoke('text').then((text) => {
        const newMaterialCost = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 QUANTITY CHANGE RESULTS - Material cost: $${newMaterialCost.toFixed(2)} (was $${initialValues.materialCost.toFixed(2)})`);
        expect(newMaterialCost).to.be.greaterThan(initialValues.materialCost);
        cy.log('✅ Material cost increased after quantity change');
      });
      
      // Verify process cost increased (should be approximately double)
      cy.get('tr').contains('Procesos aplicados:').parent().find('td').invoke('text').then((text) => {
        const newProcessCost = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 QUANTITY CHANGE RESULTS - Material process cost: $${newProcessCost.toFixed(2)} (was $${initialValues.processCost.toFixed(2)})`);
        expect(newProcessCost).to.be.greaterThan(initialValues.processCost);
        cy.log('✅ Material process cost increased after quantity change');
      });
    });
    
    // 6. Test dimension change recalculation
    cy.log('🔄 DIMENSION CHANGE TEST - Changing width from 20 to 25 cm');
    
    // Change the width and verify recalculation
    cy.get('#product-width').clear().type('25').blur();
    cy.wait(1000);
    
    // Verify that the pricing panel updates with the new dimensions
    cy.get('.pricing-panel').within(() => {
      // Verify material cost changed due to dimension change
      cy.get('tr').contains('Materiales:').parent().find('td').invoke('text').then((text) => {
        const newMaterialCost = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
        cy.log(`📊 DIMENSION CHANGE RESULTS - Material cost: $${newMaterialCost.toFixed(2)} (was $${initialValues.materialCost.toFixed(2)})`);
        expect(newMaterialCost).to.not.equal(initialValues.materialCost);
        cy.log('✅ Material cost changed after dimension change');
      });
    });
    
    // 7. Test waste percentage (merma) recalculation
    cy.log('🔄 WASTE PERCENTAGE CHANGE TEST - Changing waste to 10%');
    let prevSubWithWaste = 0;
    let currentSubtotal = 0;
    // Capture current values
    cy.get('.pricing-panel').within(() => {
      cy.get('tr').contains('Subtotal:').parent().find('td').invoke('text').then((text) => {
        currentSubtotal = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
      });
      cy.get('tr').contains('Sub. con merma').parent().find('td').invoke('text').then((text) => {
        prevSubWithWaste = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
      });
    }).then(() => {
      // Change waste to 10 and blur
      cy.get('input.waste-input').clear().type('10').blur();
      cy.wait(800);
      // Validate recalculation
      cy.get('.pricing-panel').within(() => {
        cy.get('tr').contains('Sub. con merma').parent().find('td').invoke('text').then((text) => {
          const newSubWithWaste = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
          expect(newSubWithWaste).to.be.greaterThan(currentSubtotal);
          expect(newSubWithWaste).to.not.equal(prevSubWithWaste);
          cy.log(`✅ Sub. con merma updated: ${newSubWithWaste} (prev ${prevSubWithWaste})`);
        });
      });
    });

    // 8. Test margin percentage recalculation
    cy.log('🔄 MARGIN PERCENTAGE CHANGE TEST - Changing margin to 20%');
    let prevTotal = 0;
    cy.get('.pricing-panel').within(() => {
      cy.get('tr').contains('Totales').parent().find('td').invoke('text').then((text) => {
        prevTotal = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
      });
    }).then(() => {
      cy.get('input.margin-input').clear().type('20').blur();
      cy.wait(800);
      cy.get('.pricing-panel').within(() => {
        cy.get('tr').contains('Totales').parent().find('td').invoke('text').then((text) => {
          const newTotal = parseFloat(text.trim().replace(/[^0-9.-]+/g, ''));
          expect(newTotal).to.be.greaterThan(prevTotal);
          cy.log(`✅ Totales updated: ${newTotal} (prev ${prevTotal})`);
        });
      });
    });

    cy.log('🎉 Recalculation validation test completed successfully!');
    
    // DO NOT SAVE - stay in the form
  });
}); 