require 'test_helper'

class OnboardingTest < Minitest::Test
  include ActionDispatch::Integration::Runner
  include Devise::Test::IntegrationHelpers
  
  def setup
    @app = Rails.application
    @integration_session = ActionDispatch::Integration::Session.new(@app)
  end

  test "new user registration redirects to onboarding" do
    # Arrange
    user_email = "test_onboarding_#{Time.current.to_i}@example.com"
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
    
    # Verify user has no real activity (only demo data)
    assert_not user.has_real_products?
    assert_not user.has_real_quotes?
    assert_not user.has_activity?
  end

  test "onboarding page loads correctly" do
    # Arrange - Create a user with demo data
    user = User.create!(
      email: "test_onboarding_page_#{Time.current.to_i}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    
    # Act - Sign in and visit onboarding
    sign_in user
    get onboarding_path
    
    # Assert - Should load successfully
    assert_response :success
    assert_select "h1", "¡Bienvenido a Cotalo!"
  end
end 