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
    cy.get('input[name="quote[customer_name]"]').type('Test Customer')
    cy.get('input[name="quote[customer_organization]"]').type('Test Organization')
    cy.get('input[name="quote[customer_email]"]').type('test@example.com')
    cy.get('input[name="quote[customer_phone]"]').type('1234567890')
    cy.get('textarea[name="quote[description]"]').type('This is a test quote')
    
    // Add a product to the quote
    cy.get('select[name="quote[product_id]"]').select('1')
    cy.get('input[name="quote[quantity]"]').type('2')
    
    // Submit the form
    cy.get('form').submit()
    
    // Assert success message
    cy.contains('Quote was successfully created').should('be.visible')
    
    // Verify the quote was created
    cy.url().should('include', '/quotes/')
    cy.contains('Test Customer').should('be.visible')
  })

  it('should show validation errors for invalid input', () => {
    // Try to submit without filling required fields
    cy.get('form').submit()
    
    // Assert validation errors
    cy.contains('Customer name can\'t be blank').should('be.visible')
    cy.contains('Customer email can\'t be blank').should('be.visible')
    cy.contains('Description can\'t be blank').should('be.visible')
  })
}) 