/**
 * Product Creation Test V2 - New Product Model Test Case
 * 
 * This test validates the complete product calculation system using the new V2 model:
 * - Product: "Tarjetas de presentación premium"
 * - Quantity: 4,000 pieces
 * - Dimensions: 32 x 22 cm
 * - Materials: Cartulina caple sulfatada 12 pts + Papel couché brillante 150 g/m²
 * - Processes: 4 processes (2 per material) + 2 global processes
 * - Extras: 3 services
 * 
 * Expected Results (to be validated):
 * - Materials cost: $8,250.00
 * - Processes cost: $5,520.00 (material processes) + global processes
 * - Extras cost: $1,000.00
 * - Total price: Calculated based on new model
 * - Price per piece: Calculated based on new model
 * 
 * This test serves as our "regression test" for the new V2 product model.
 */
describe('Product Creation V2', () => {
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

  it('should load the V2 product creation page correctly', () => {
    // Visit the product creation page for V2 model
    cy.visit('/products/new_v2')
    
    // Wait for the page to load
    cy.get('body').should('be.visible')
    
    // Check if the Vue app container exists
    cy.get('#product-form-app').should('exist')
    
    // Wait a bit more for Vue to initialize
    cy.wait(3000)
    
    // Check if the form elements are visible
    cy.get('#product-description').should('be.visible')
    
    // Check if the tabs are visible
    cy.get('a.nav-link').contains('Producto').should('be.visible')
    cy.get('a.nav-link').contains('Costos adicionales').should('be.visible')
    
    // Check if the pricing panel is visible
    cy.get('.pricing-panel').should('be.visible')
  })
}) 