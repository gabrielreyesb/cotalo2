/**
 * Product Calculation Test V2 - Basic Page Load Validation
 * 
 * This test validates that the V2 product creation page loads correctly
 * and basic elements are present.
 */
describe('Product Calculation V2 - Basic Page Load', () => {
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

  it('should load the V2 product creation page and verify basic elements', () => {
    // Visit the product creation page
    cy.visit('/products/new_v2')
    
    // Wait for the page to load
    cy.get('body').should('be.visible')
    cy.wait(2000)
    
    // Check if the Vue app container exists
    cy.get('#product-form-app').should('exist')
    cy.wait(2000)
    
    // Check if basic form elements are visible
    cy.get('#product-description').should('be.visible')
    cy.get('#product-quantity').should('be.visible')
    cy.get('#product-width').should('be.visible')
    cy.get('#product-length').should('be.visible')
    
    // Check if tabs are visible
    cy.get('a.nav-link').contains('Producto').should('be.visible')
    cy.get('a.nav-link').contains('Costos adicionales').should('be.visible')
    
    // Check if pricing panel is visible
    cy.get('.pricing-panel').should('be.visible')
    
    // Log success
    cy.log('✅ V2 Product creation page loaded successfully')
    cy.log('✅ All basic elements are present')
  })

  it('should verify that the page is functional by filling basic information', () => {
    // Visit the product creation page
    cy.visit('/products/new_v2')
    
    // Wait for the page to load
    cy.get('body').should('be.visible')
    cy.get('#product-form-app').should('exist')
    cy.wait(3000)
    
    // Fill basic product information
    cy.get('#product-description').type('Prueba Básica V2')
    cy.get('#product-quantity').type('100')
    cy.get('#product-width').type('20')
    cy.get('#product-length').type('30')
    
    // Verify the information was entered
    cy.get('#product-description').should('have.value', 'Prueba Básica V2')
    cy.get('#product-quantity').should('have.value', '100')
    cy.get('#product-width').should('have.value', '20')
    cy.get('#product-length').should('have.value', '30')
    
    cy.log('✅ Basic form information can be entered successfully')
  })
}) 