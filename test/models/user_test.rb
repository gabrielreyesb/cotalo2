require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    # Clear any existing test data
    User.destroy_all
    Unit.destroy_all
  end

  test "setup_initial_data creates demo data for new user" do
    user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Verify units were created
    assert_equal 3, Unit.count
    assert Unit.find_by(name: 'mt2')
    assert Unit.find_by(name: 'pieza')
    assert Unit.find_by(name: 'pliego')

    # Verify materials were created
    assert_equal 3, user.materials.count
    assert user.materials.find_by(description: 'Caple 12 puntos')
    assert user.materials.find_by(description: 'Cartulina multicapa 14 pts')
    assert user.materials.find_by(description: 'Liner Kraft 180 gramos')

    # Verify manufacturing processes were created
    assert_equal 3, user.manufacturing_processes.count
    assert user.manufacturing_processes.find_by(name: 'Empalmado')
    assert user.manufacturing_processes.find_by(name: 'Pegado lineal')
    assert user.manufacturing_processes.find_by(name: 'Impresión flexográfica')

    # Verify extras were created
    assert_equal 2, user.extras.count
    assert user.extras.find_by(name: 'Placas de impresión 4 oficios')
    assert user.extras.find_by(name: 'Suaje plano')

    # Verify price margins were created
    assert_equal 3, user.price_margins.count
    assert user.price_margins.find_by(min_price: 0, max_price: 5000)
    assert user.price_margins.find_by(min_price: 5001, max_price: 50000)
    assert user.price_margins.find_by(min_price: 50001, max_price: 200000)

    # Verify test product was created
    assert_equal 1, user.products.count
    test_product = user.products.first
    assert_equal "Producto de prueba", test_product.description

    # Verify product data structure
    assert test_product.data.present?
    assert test_product.data["general_info"].present?
    assert test_product.data["materials"].present?
    assert test_product.data["processes"].present?
    assert test_product.data["extras"].present?
    assert test_product.data["pricing"].present?

    # Verify general info
    general_info = test_product.data["general_info"]
    assert_equal 50, general_info["width"]
    assert_equal 30, general_info["length"]
    assert_equal 100, general_info["quantity"]
    assert_equal "Producto de demostración para nuevos usuarios", general_info["comments"]

    # Verify materials in product
    materials = test_product.data["materials"]
    assert_equal 2, materials.length
    
    # Check first material
    first_material = materials[0]
    assert first_material["material_id"].present?
    assert_equal "Material principal del producto", first_material["comments"]
    assert_equal 50, first_material["width"]
    assert_equal 30, first_material["length"]
    assert_equal 100, first_material["quantity"]
    assert_equal 6, first_material["pieces_per_material"]
    assert_equal 17, first_material["total_sheets"]
    assert_equal 25.5, first_material["total_square_meters"]
    assert_equal 255.0, first_material["subtotal_price"]

    # Check second material
    second_material = materials[1]
    assert second_material["material_id"].present?
    assert_equal "Material secundario para detalles", second_material["comments"]
    assert_equal 25, second_material["width"]
    assert_equal 15, second_material["length"]
    assert_equal 100, second_material["quantity"]
    assert_equal 24, second_material["pieces_per_material"]
    assert_equal 5, second_material["total_sheets"]
    assert_equal 1.875, second_material["total_square_meters"]
    assert_equal 22.5, second_material["subtotal_price"]

    # Verify processes in product
    processes = test_product.data["processes"]
    assert_equal 2, processes.length
    
    # Check first process
    first_process = processes[0]
    assert first_process["process_id"].present?
    assert_equal "Proceso principal de empalmado", first_process["comments"]
    assert_equal 25.5, first_process["quantity"]
    assert_equal 89.25, first_process["subtotal_price"]

    # Check second process
    second_process = processes[1]
    assert second_process["process_id"].present?
    assert_equal "Pegado lineal para cada pieza", second_process["comments"]
    assert_equal 100, second_process["quantity"]
    assert_equal 35.0, second_process["subtotal_price"]

    # Verify extras in product
    extras = test_product.data["extras"]
    assert_equal 1, extras.length
    
    # Check extra
    extra = extras[0]
    assert extra["extra_id"].present?
    assert_equal "Placas necesarias para la impresión", extra["comments"]
    assert_equal 1, extra["quantity"]
    assert_equal 250.0, extra["subtotal_price"]

    # Verify pricing calculations
    pricing = test_product.data["pricing"]
    assert_equal 277.5, pricing["materials_cost"]
    assert_equal 124.25, pricing["processes_cost"]
    assert_equal 250.0, pricing["extras_cost"]
    assert_equal 651.75, pricing["subtotal"]
    assert_equal 5, pricing["waste_percentage"]
    assert_equal 32.59, pricing["waste_value"]
    assert_equal 6.84, pricing["price_per_piece_before_margin"]
    assert_equal 10, pricing["margin_percentage"]
    assert_equal 68.43, pricing["margin_value"]
    assert_equal 752.77, pricing["total_price"]
    assert_equal 7.53, pricing["final_price_per_piece"]
  end

  test "setup_initial_data sets correct app configs" do
    user = User.create!(
      email: 'config@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Verify app configs were set
    assert_equal 0, user.get_config('waste_percentage')
    assert_equal 0, user.get_config('width_margin')
    assert_equal 0, user.get_config('length_margin')
  end

  test "setup_initial_data handles errors gracefully" do
    # Mock the materials creation to raise an error
    User.any_instance.stubs(:materials).raises(StandardError.new("Database error"))

    assert_raises(StandardError) do
      User.create!(
        email: 'error@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end
  end

  test "setup_initial_data creates units with correct abbreviations" do
    user = User.create!(
      email: 'units@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    mt2_unit = Unit.find_by(name: 'mt2')
    pieza_unit = Unit.find_by(name: 'pieza')
    pliego_unit = Unit.find_by(name: 'pliego')

    assert_equal 'm²', mt2_unit.abbreviation
    assert_equal 'pieza', pieza_unit.abbreviation
    assert_equal 'pliego', pliego_unit.abbreviation
  end

  test "setup_initial_data creates materials with correct associations" do
    user = User.create!(
      email: 'materials@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    mt2_unit = Unit.find_by(name: 'mt2')
    
    # Verify materials are associated with the correct unit
    user.materials.each do |material|
      assert_equal mt2_unit, material.unit
      assert_equal 100, material.ancho
      assert_equal 100, material.largo
    end
  end

  test "setup_initial_data creates processes with correct associations" do
    user = User.create!(
      email: 'processes@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    mt2_unit = Unit.find_by(name: 'mt2')
    pieza_unit = Unit.find_by(name: 'pieza')
    pliego_unit = Unit.find_by(name: 'pliego')

    # Verify processes are associated with correct units
    empalmado = user.manufacturing_processes.find_by(name: 'Empalmado')
    pegado = user.manufacturing_processes.find_by(name: 'Pegado lineal')
    impresion = user.manufacturing_processes.find_by(name: 'Impresión flexográfica')

    assert_equal mt2_unit, empalmado.unit
    assert_equal pieza_unit, pegado.unit
    assert_equal pliego_unit, impresion.unit
  end

  test "setup_initial_data creates extras with correct associations" do
    user = User.create!(
      email: 'extras@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    pieza_unit = Unit.find_by(name: 'pieza')

    # Verify extras are associated with correct units
    user.extras.each do |extra|
      assert_equal pieza_unit, extra.unit
    end
  end

  test "setup_initial_data creates price margins with correct ranges" do
    user = User.create!(
      email: 'margins@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Verify price margins have correct ranges and percentages
    margin_1 = user.price_margins.find_by(min_price: 0, max_price: 5000)
    margin_2 = user.price_margins.find_by(min_price: 5001, max_price: 50000)
    margin_3 = user.price_margins.find_by(min_price: 50001, max_price: 200000)

    assert_equal 10, margin_1.margin_percentage
    assert_equal 15, margin_2.margin_percentage
    assert_equal 25, margin_3.margin_percentage
  end
end
