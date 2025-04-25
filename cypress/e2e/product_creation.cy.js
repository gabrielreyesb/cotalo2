describe('Product Creation', () => {
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

  beforeEach(() => {
    // Visit the product creation page
    cy.visit('/products/new')
    
    // Wait for the Vue app to load
    cy.get('#product-form-app').should('exist')
    
    // Wait for the form to be ready
    cy.get('#product-description').should('be.visible')
  })

  it('should create a new product with correct pricing calculations', () => {
    // Fill in the product form
    cy.get('#product-description').type('Test Product')
    cy.get('#product-quantity').type('3000')
    cy.get('#product-width').type('32')
    cy.get('#product-length').type('22')
    
    // Wait for Vue to update the form data
    cy.wait(1000)
    
    // Click on the Materials tab
    cy.get('a.nav-link').contains('Materiales').click({ force: true })
    
    // Wait for the materials tab to load and be visible
    cy.get('.materials-tab').should('be.visible')
    
    // Wait for the material select to be ready
    cy.get('#material-select').should('exist')
    
    // Select the first material
    cy.get('#material-select').select(1, { force: true })
    
    // Click the Add Material button
    cy.contains('Agregar material').click()
    
    // Wait for the material to be added and pricing to update
    cy.wait(1000)
    
    // Click on the Processes tab
    cy.get('a.nav-link').contains('Procesos').click({ force: true })
    
    // Wait for the processes tab to load and be visible
    cy.get('.processes-tab').should('be.visible')
    
    // Wait for the process select to be ready
    cy.get('#process-select').should('exist')
    
    // Select the first process
    cy.get('#process-select').select(1, { force: true })
    
    // Click the Add Process button
    cy.contains('Agregar Proceso').click()
    
    // Wait for the process to be added and pricing to update
    cy.wait(1000)
    
    // Click on the Extras tab
    cy.get('a.nav-link').contains('Extras').click({ force: true })
    
    // Wait for the extras tab to load and be visible
    cy.get('.extras-tab').should('be.visible')
    
    // Wait for the extra select to be ready
    cy.get('#extra-select').should('exist')
    
    // Select the first extra
    cy.get('#extra-select').select(1, { force: true })
    
    // Click the Add Extra button
    cy.contains('Agregar Extra').click()
    
    // Wait for the extra to be added and pricing to update
    cy.wait(1000)

    // Define expected values with correct format (using , for thousands and . for decimals)
    const expectedValues = {
      materialsCost: '$582.75',
      processesCost: '$31,500.00',
      extrasCost: '$2,000.00',
      subtotal: '$34,082.75',
      wasteValue: '$1,704.14',
      subtotalWithWaste: '$35,786.89',
      pricePerPieceBeforeMargin: '$11.93',
      marginValue: '$3,578.69',
      totalPrice: '$39,365.58',
      finalPricePerPiece: '$13.12'
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
    cy.contains('Test Product').should('be.visible')
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