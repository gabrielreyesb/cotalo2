require 'test_helper'

class OnboardingFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "new user registration flow redirects to onboarding" do
    # Arrange
    user_email = "onboarding_test_#{Time.current.to_i}@example.com"
    user_params = {
      user: {
        email: user_email,
        password: "password123",
        password_confirmation: "password123",
        name: "Onboarding Test User"
      }
    }

    # Act - Register new user
    assert_difference 'User.count', 1 do
      post user_registration_path, params: user_params
    end

    # Assert - Should redirect to onboarding
    assert_redirected_to onboarding_path
    
    # Verify user was created with demo data
    user = User.find_by(email: user_email)
    assert_not_nil user
    assert_equal "Onboarding Test User", user.name
    
    # Verify demo products were created
    assert_equal 3, user.products.count
    assert user.products.exists?(description: "Caja plegadiza cosmética – cartulina caple 12 pts")
    assert user.products.exists?(description: "Folder corporativo institucional – Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado.")
    assert user.products.exists?(description: "Tríptico promocional 21×29.7 cm – Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante.")
    
    # Verify demo quotes were created
    assert_equal 2, user.quotes.count
    assert user.quotes.exists?(project_name: "Caja plegadiza para producto cosmético premium")
    assert user.quotes.exists?(project_name: "Campaña de Marketing Corporativo Q4 2024")
    
    # Verify user has no real activity (only demo data)
    assert_not user.has_real_products?
    assert_not user.has_real_quotes?
    assert_not user.has_activity?
  end

  test "onboarding page loads correctly" do
    # Arrange - Create a user with demo data
    user = User.create!(
      email: "onboarding_page_test_#{Time.current.to_i}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Onboarding Page Test User"
    )
    
    # Act - Sign in and visit onboarding
    sign_in user
    get onboarding_path
    
    # Assert - Should load successfully
    assert_response :success
    assert_select "h1", "¡Bienvenido a Cotalo!"
    assert_select ".guide-section", 2 # Two guide sections
    assert_select ".quick-actions-section" # Quick actions section
  end

  test "user with real activity goes to dashboard" do
    # Arrange - Create user with real product
    user = User.create!(
      email: "real_activity_test_#{Time.current.to_i}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Real Activity Test User"
    )
    
    # Add a real product
    user.products.create!(
      description: "Real Product Created by User",
      data: { general_info: { width: 10, length: 10, quantity: 100 } }
    )
    
    # Act - Sign in
    sign_in user
    get dashboard_path
    
    # Assert - Should be on dashboard, not redirected to onboarding
    assert_response :success
  end

  test "user without real activity goes to onboarding" do
    # Arrange - Create user with only demo data
    user = User.create!(
      email: "no_activity_test_#{Time.current.to_i}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "No Activity Test User"
    )
    
    # Verify user has demo data but no real activity
    assert_equal 3, user.products.count
    assert_equal 2, user.quotes.count
    assert_not user.has_real_products?
    assert_not user.has_real_quotes?
    assert_not user.has_activity?
    
    # Act - Sign in
    sign_in user
    get dashboard_path
    
    # Assert - Should redirect to onboarding
    assert_redirected_to onboarding_path
  end
end 