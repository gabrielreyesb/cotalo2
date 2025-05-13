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
  })

  it('should create a new quote successfully', () => {
    // Fill in the quote form
    cy.get('#customer_name').type('Test Customer')
    cy.get('#organization').type('Test Organization')
    cy.get('#email').type('test@example.com')
    cy.get('#telephone').type('1234567890')
    cy.get('#comments').type('This is a test quote')
    
    // Ensure there is at least one product to select
    cy.get('#product-select option').should('have.length.greaterThan', 1);

    // Log all option texts
    cy.get('#product-select option').each(($option) => {
      cy.log($option.text());
    });

    // Select the first real product option dynamically
    cy.get('#product-select option').eq(1).then($option => {
      cy.get('#product-select').select($option.text());
    });

    // Add the product to the quote
    cy.contains('Agregar a la cotización').click();

    // Ensure the product is added to the quote
    cy.get('.table').contains('Test Product').should('be.visible');

    // Re-type the project name in case it was cleared
    cy.get('#project_name').clear().type('Test Project');
    
    // Submit the form
    cy.get('#save-quote-button').click()
    
    // Verify the quote was created
    cy.url().should('include', '/quotes')
    cy.contains('Test Customer').should('be.visible')
  })
}) 