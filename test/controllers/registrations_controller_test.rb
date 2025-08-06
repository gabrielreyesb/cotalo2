require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "new user registration redirects to onboarding" do
    # Arrange
    user_email = "test_user_#{Time.current.to_i}@example.com"
    user_params = {
      user: {
        email: user_email,
        password: "password123",
        password_confirmation: "password123",
        name: "Test User"
      }
    }

    # Act - Register new user
    assert_difference 'User.count', 1 do
      post user_registration_path, params: user_params
    end

    # Assert - Should redirect to onboarding
    assert_redirected_to onboarding_path
    
    # Verify user was created
    user = User.find_by(email: user_email)
    assert_not_nil user
    assert_equal "Test User", user.name
    
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

  test "new user session flag is set correctly" do
    # Arrange
    user_email = "test_user_#{Time.current.to_i}@example.com"
    user_params = {
      user: {
        email: user_email,
        password: "password123",
        password_confirmation: "password123",
        name: "Test User"
      }
    }

    # Act - Register new user
    post user_registration_path, params: user_params
    
    # Assert - Should redirect to onboarding
    assert_redirected_to onboarding_path
    
    # Follow the redirect to verify onboarding page loads
    follow_redirect!
    assert_response :success
    assert_select "h1", "¡Bienvenido a Cotalo!"
  end

  test "existing user with real activity redirects to dashboard" do
    # Arrange - Create user with real products
    user = User.create!(
      email: "real_activity_user_#{Time.current.to_i}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Real Activity User"
    )
    user.products.create!(
      description: "Real Product Created by User",
      data: { general_info: { width: 10, length: 10, quantity: 100 } }
    )
    
    # Act - Sign in existing user
    sign_in user
    get dashboard_path
    
    # Assert - Should be on dashboard, not onboarding
    assert_response :success
    # Note: Adjust selector based on your actual dashboard content
  end

  test "existing user without real activity redirects to onboarding" do
    # Arrange - Create user with only demo data
    user = User.create!(
      email: "demo_only_user@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Demo Only User"
    )
    
    # Verify user has demo data but no real activity
    assert_equal 3, user.products.count
    assert_equal 2, user.quotes.count
    assert_not user.has_real_products?
    assert_not user.has_real_quotes?
    assert_not user.has_activity?
    
    # Act - Sign in user
    sign_in user
    get dashboard_path
    
    # Assert - Should redirect to onboarding
    assert_redirected_to onboarding_path
  end

  test "demo products are correctly identified and excluded" do
    # Arrange
    user = User.create!(
      email: "test_demo_products@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test Demo Products"
    )
    
    # Act - Check has_real_products? method
    real_products_count = user.products.where.not(
      description: [
        "Caja plegadiza cosmética – cartulina caple 12 pts",
        "Folder corporativo institucional – Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado.",
        "Tríptico promocional 21×29.7 cm – Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante."
      ]
    ).count
    
    # Assert
    assert_equal 0, real_products_count
    assert_not user.has_real_products?
  end

  test "demo quotes are correctly identified and excluded" do
    # Arrange
    user = User.create!(
      email: "test_demo_quotes@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test Demo Quotes"
    )
    
    # Act - Check has_real_quotes? method
    real_quotes_count = user.quotes.where.not(
      project_name: [
        "Caja plegadiza para producto cosmético premium",
        "Campaña de Marketing Corporativo Q4 2024"
      ]
    ).count
    
    # Assert
    assert_equal 0, real_quotes_count
    assert_not user.has_real_quotes?
  end
end 