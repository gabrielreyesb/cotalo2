/**
 * Product Creation Test - Validated Calculation Test Case
 * 
 * This test validates the complete product calculation system using a real-world scenario:
 * - Product: "Tarjetas de presentación premium"
 * - Quantity: 4,000 pieces
 * - Dimensions: 32 x 22 cm
 * - Materials: Cartulina caple sulfatada 12 pts + Papel couché brillante 150 g/m²
 * - Processes: 4 processes (2 per material)
 * - Extras: 3 services
 * 
 * Expected Results (validated manually):
 * - Materials cost: $8,250.00
 * - Processes cost: $5,520.00
 * - Extras cost: $1,000.00
 * - Total price: $17,834.78
 * - Price per piece: $4.46
 * 
 * This test serves as our "regression test" to ensure calculations remain accurate.
 */
describe('Product Creation', () => {
  before(() => {
    // Visit the login page
    cy.visit('/users/sign_in')
    
    // Fill in login form
    cy.get('input[name="user[email]"]').type('gabrielreyesb+51@gmail.com')
    cy.get('input[name="user[password]"]').type('123456')
    cy.get('form').submit()
    
    // Wait for login to complete
    cy.url().should('not.include', '/users/sign_in')
  })

  beforeEach(() => {
    // Visit the product creation page
    cy.visit('/products/new')
    
    // Wait for the Vue app to load
    cy.get('#product-form-app').should('exist')
    
    // Wait for the form to be ready
    cy.get('#product-description').should('be.visible')
  })

  it('should create a new product with correct pricing calculations', () => {
    // Fill in the product form with our test case data
    cy.get('#product-description').type('Tarjetas de presentación premium')
    cy.get('#product-quantity').type('4000')
    cy.get('#product-width').type('32')
    cy.get('#product-length').type('22')
    
    // Wait for Vue to update the form data
    cy.wait(1000)
    
    // Click on the Materials tab
    cy.get('a.nav-link').contains('Materiales').click({ force: true })
    
    // Wait for the materials tab to load and be visible
    cy.get('.materials-tab').should('be.visible')
    
    // Wait for the material multiselect to be ready
    cy.get('.multiselect').should('exist')
    
    // Add first material: Cartulina caple sulfatada 12 pts
    cy.get('.multiselect').first().click()
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Cartulina caple sulfatada 12 pts').click({ force: true })
    cy.wait(500) // Wait for selection to complete
    cy.contains('Agregar material').click()
    cy.wait(1000)
    
    // Add second material: Papel couché brillante 150 g/m²
    cy.get('.multiselect').first().click()
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Papel couché brillante 150 g/m²').click({ force: true })
    cy.wait(500) // Wait for selection to complete
    cy.contains('Agregar material').click()
    cy.wait(1000)
    
    // Click on the Processes tab
    cy.get('a.nav-link').contains('Procesos').click({ force: true })
    
    // Wait for the processes tab to load and be visible
    cy.get('.processes-tab').should('be.visible')
    
    // Wait for the process multiselect to be ready
    cy.get('.multiselect').should('have.length.at.least', 2)
    
    // Add processes for first material: Cartulina caple sulfatada 12 pts
    // First, select the material
    cy.get('.multiselect').first().click() // Material select in processes tab
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Cartulina caple sulfatada 12 pts (1)').click({ force: true })
    // Then select the process
    cy.get('.multiselect').eq(1).click() // Process select
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Impresión offset 4 tintas (CMYK)').click({ force: true })
    cy.get('.processes-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)
    
    // Add second process for first material (material should already be selected)
    cy.wait(2000) // Wait for UI to stabilize after adding the first process
    // The material should already be selected, so just select the process
    cy.get('.multiselect').eq(1).click() // Process select
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Barniz UV spot').click({ force: true })
    cy.get('.processes-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)
    
    // Add processes for second material: Papel couché brillante 150 g/m²
    cy.wait(2000) // Wait for UI to stabilize
    cy.get('.multiselect').first().click() // Material select in processes tab
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Papel couché brillante 150 g/m² (1)').click({ force: true })
    cy.wait(500) // Wait for material selection to complete
    cy.get('.multiselect').eq(1).click() // Process select
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Troquelado').click({ force: true })
    cy.get('.processes-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)
    
    // Add second process for second material (material should already be selected)
    cy.wait(2000) // Wait for UI to stabilize
    // The material should already be selected, so just select the process
    cy.get('.multiselect').eq(1).click() // Process select
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Hendido y corte').click({ force: true })
    cy.get('.processes-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)
    
    // Click on the Extras tab
    cy.get('a.nav-link').contains('Indirectos').click({ force: true })
    
    // Wait for the extras tab to load and be visible
    cy.get('.extras-tab').should('be.visible')
    
    // Wait for the extra multiselect to be ready
    cy.get('.multiselect').should('exist')
    
    // Add extras
    cy.get('.multiselect').first().click() // Extra select in extras tab
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Diseño gráfico editorial').click({ force: true })
    cy.get('.extras-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)
    
    cy.get('.multiselect').first().click() // Extra select in extras tab
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Ajuste de archivos para impresión').click({ force: true })
    cy.get('.extras-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)
    
    cy.get('.multiselect').first().click() // Extra select in extras tab
    cy.get('.multiselect__content-wrapper').should('be.visible')
    cy.get('.multiselect__option').contains('Prueba de color digital (matchprint)').click({ force: true })
    cy.get('.extras-tab .btn-primary').should('not.be.disabled').click();
    cy.wait(1000)

    // Define expected values with correct format (using , for thousands and . for decimals)
    // Based on our validated test case: 4000 pieces of 32x22 cm with real prices
    const expectedValues = {
      materialsCost: '$8,250.00',
      processesCost: '$5,520.00',
      extrasCost: '$1,000.00',
      subtotal: '$14,770.00',
      wasteValue: '$738.50',
      subtotalWithWaste: '$15,508.50',
      pricePerPieceBeforeMargin: '$3.88',
      marginValue: '$2,326.28',
      totalPrice: '$17,834.78',
      finalPricePerPiece: '$4.46'
    };

    // Helper function to verify price value with better error message
    const verifyPrice = (selector, expectedValue, description) => {
      cy.get('td.text-end, .calculated-value').then($cells => {
        // Get text content from both direct cells and nested calculated-value divs
        const cellValues = Array.from($cells).map(cell => {
          // Try to find a nested calculated-value div first
          const calculatedValue = cell.querySelector('.calculated-value');
          if (calculatedValue) {
            return calculatedValue.textContent.trim();
          }
          // If no nested div, use the cell's own text
          return cell.textContent.trim();
        });
        
        // Normalize the values by removing extra spaces
        const normalizedCellValues = cellValues.map(value => value.replace(/\s+/g, ' ').trim());
        const normalizedExpectedValue = expectedValue.replace(/\s+/g, ' ').trim();
        
        const actualValue = normalizedCellValues.find(value => value === normalizedExpectedValue);
        
        expect(
          actualValue,
          `Expected ${description} to be ${expectedValue}, but found these values instead: ${normalizedCellValues.join(', ')}`
        ).to.equal(normalizedExpectedValue);
      });
    };

    // Verify all pricing calculations with descriptive messages
    verifyPrice('td', expectedValues.materialsCost, 'Materials cost');
    verifyPrice('td', expectedValues.processesCost, 'Processes cost');
    verifyPrice('td', expectedValues.extrasCost, 'Extras cost');
    verifyPrice('td', expectedValues.subtotal, 'Subtotal');
    verifyPrice('td', expectedValues.wasteValue, 'Waste value');
    verifyPrice('td', expectedValues.subtotalWithWaste, 'Subtotal with waste');
    verifyPrice('td', expectedValues.pricePerPieceBeforeMargin, 'Price per piece before margin');
    verifyPrice('td', expectedValues.marginValue, 'Margin value');
    verifyPrice('td', expectedValues.totalPrice, 'Total price');
    verifyPrice('td', expectedValues.finalPricePerPiece, 'Final price per piece');
    
    // Click the save button
    cy.get('#save-product-button').click()
    
    // Verify the product was created and we're on the products page
    cy.url().should('include', '/products')
    cy.contains('Tarjetas de presentación premium').should('be.visible')
  })

  // it('should show validation errors for invalid input', () => {
  //   // Click the save button without filling required fields
  //   cy.get('#save-product-button').click()
  //   
  //   // Handle the alert
  //   cy.on('window:alert', (str) => {
  //     expect(str).to.include('La descripción es requerida')
  //   })
  // })
}) 