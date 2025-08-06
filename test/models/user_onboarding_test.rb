require 'test_helper'

class UserOnboardingTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test_onboarding_#{Time.current.to_i}_#{rand(1000)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test Onboarding User"
    )
  end

  test "new user has no real products initially" do
    # Arrange & Act
    @user.save!
    
    # Assert
    assert_equal 3, @user.products.count # Demo products
    assert_not @user.has_real_products?
    assert_equal 0, @user.products.where.not(
      description: [
        "Caja plegadiza cosmética – cartulina caple 12 pts",
        "Folder corporativo institucional – Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado.",
        "Tríptico promocional 21×29.7 cm – Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante."
      ]
    ).count
  end

  test "new user has no real quotes initially" do
    # Arrange & Act
    @user.save!
    
    # Assert
    assert_equal 2, @user.quotes.count # Demo quotes
    assert_not @user.has_real_quotes?
    assert_equal 0, @user.quotes.where.not(
      project_name: [
        "Caja plegadiza para producto cosmético premium",
        "Campaña de Marketing Corporativo Q4 2024"
      ]
    ).count
  end

  test "new user has no real activity initially" do
    # Arrange & Act
    @user.save!
    
    # Assert
    assert_not @user.has_real_products?
    assert_not @user.has_real_quotes?
    assert_not @user.has_activity?
  end

  test "user with real product has activity" do
    # Arrange
    @user.save!
    
    # Act - Add a real product
    @user.products.create!(
      description: "Real Product Created by User",
      data: { general_info: { width: 10, length: 10, quantity: 100 } }
    )
    
    # Assert
    assert @user.has_real_products?
    assert @user.has_activity?
  end

  test "user with real quote has activity" do
    # Arrange
    @user.save!
    
    # Act - Add a real quote
    @user.quotes.create!(
      project_name: "Real Quote Created by User",
      client_name: "Test Client"
    )
    
    # Assert
    assert @user.has_real_quotes?
    assert @user.has_activity?
  end

  test "demo products are correctly excluded from real products count" do
    # Arrange
    @user.save!
    
    # Act - Add a real product
    real_product = @user.products.create!(
      description: "Real Product Created by User",
      data: { general_info: { width: 10, length: 10, quantity: 100 } }
    )
    
    # Assert
    assert_equal 4, @user.products.count # 3 demo + 1 real
    assert @user.has_real_products?
    
    # Verify the specific product is counted as real
    real_products = @user.products.where.not(
      description: [
        "Caja plegadiza cosmética – cartulina caple 12 pts",
        "Folder corporativo institucional – Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado.",
        "Tríptico promocional 21×29.7 cm – Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante."
      ]
    )
    assert_equal 1, real_products.count
    assert_equal real_product.id, real_products.first.id
  end

  test "demo quotes are correctly excluded from real quotes count" do
    # Arrange
    @user.save!
    
    # Act - Add a real quote
    real_quote = @user.quotes.create!(
      project_name: "Real Quote Created by User",
      client_name: "Test Client"
    )
    
    # Assert
    assert_equal 3, @user.quotes.count # 2 demo + 1 real
    assert @user.has_real_quotes?
    
    # Verify the specific quote is counted as real
    real_quotes = @user.quotes.where.not(
      project_name: [
        "Caja plegadiza para producto cosmético premium",
        "Campaña de Marketing Corporativo Q4 2024"
      ]
    )
    assert_equal 1, real_quotes.count
    assert_equal real_quote.id, real_quotes.first.id
  end

  test "setup_initial_data creates correct demo products" do
    # Arrange & Act
    @user.save!
    
    # Assert - Verify all 3 demo products were created
    demo_products = [
      "Caja plegadiza cosmética – cartulina caple 12 pts",
      "Folder corporativo institucional – Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado.",
      "Tríptico promocional 21×29.7 cm – Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante."
    ]
    
    demo_products.each do |description|
      assert @user.products.exists?(description: description), 
             "Demo product '#{description}' was not created"
    end
  end

  test "setup_initial_data creates correct demo quotes" do
    # Arrange & Act
    @user.save!
    
    # Assert - Verify both demo quotes were created
    demo_quotes = [
      "Caja plegadiza para producto cosmético premium",
      "Campaña de Marketing Corporativo Q4 2024"
    ]
    
    demo_quotes.each do |project_name|
      assert @user.quotes.exists?(project_name: project_name), 
             "Demo quote '#{project_name}' was not created"
    end
  end

  test "setup_initial_data creates demo materials and processes" do
    # Arrange & Act
    @user.save!
    
    # Assert - Verify demo materials were created
    assert @user.materials.exists?(description: "Cartulina caple sulfatada 12 pts")
    assert @user.materials.exists?(description: "Cartulina caple sulfatada 14 pts")
    assert @user.materials.exists?(description: "Papel couché brillante 150 g/m²")
    
    # Assert - Verify demo processes were created
    assert @user.manufacturing_processes.exists?(name: "Impresión offset 4 tintas (CMYK)")
    assert @user.manufacturing_processes.exists?(name: "Barniz UV spot")
    assert @user.manufacturing_processes.exists?(name: "Troquelado")
  end

  test "setup_initial_data creates demo extras" do
    # Arrange & Act
    @user.save!
    
    # Assert - Verify demo extras were created
    assert @user.extras.exists?(name: "Fabricación de troquel")
    assert @user.extras.exists?(name: "Diseño gráfico del empaque")
    assert @user.extras.exists?(name: "Supervisión de producción")
  end

  test "setup_initial_data sets default app configs" do
    # Arrange & Act
    @user.save!
    
    # Assert - Verify default configs were set
    assert_equal 5.0, @user.waste_percentage
    assert_equal 2, @user.width_margin
    assert_equal 2, @user.length_margin
    assert_equal "Cotalo", @user.get_config('customer_name')
    assert_equal "Cotalo", @user.get_config('company_name')
    assert_equal "dark", @user.get_config(AppConfig::THEME)
  end
end 