describe('Quote Creation', () => {
  beforeEach(() => {
    // Visit the login page
    cy.visit('/users/sign_in')
    
    // Fill in login form
    cy.get('input[name="user[email]"]').type('gabrielreyesb@gmail.com')
    cy.get('input[name="user[password]"]').type('123456')
    cy.get('form').submit()
    
    // Wait for login to complete
    cy.url().should('not.include', '/users/sign_in')
    
    // Visit the quote creation page
    cy.visit('/quotes/new')
    
    // Wait for Vue app to load
    cy.get('#quote-form-app').should('exist')
    cy.wait(2000) // Wait for Vue to initialize
  })

  it('should create a new quote successfully', () => {
    // Fill in the quote form
    cy.get('#project_name').type('Test Project')
    cy.get('#customer_name').type('Test Customer')
    cy.get('#organization').type('Test Organization')
    cy.get('#email').type('test@example.com')
    cy.get('#telephone').type('1234567890')
    cy.get('#comments').type('This is a test quote')
    
    // Wait for the multiselect to be ready (Vue component)
    cy.get('.multiselect').should('exist')
    
    // Click on the multiselect to open it
    cy.get('.multiselect').first().click()
    
    // Wait for the dropdown to appear
    cy.get('.multiselect__content-wrapper').should('be.visible')
    
    // Select the first available product
    cy.get('.multiselect__option').first().click()
    
    // Click the "Add to quote" button
    cy.contains('Agregar a la cotización').click()
    
    // Verify that a product was added (look for the table or product list)
    cy.get('.table, .selected-products, [data-testid="selected-products"]').should('exist')
    
    // Submit the form
    cy.get('#save-quote-button').click()
    
    // Verify the quote was created
    cy.url().should('include', '/quotes')
    cy.contains('Test Customer').should('be.visible')
  })
}) 