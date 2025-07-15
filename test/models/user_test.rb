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
    assert_equal 5, Unit.count
    assert Unit.find_by(name: 'mt2')
    assert Unit.find_by(name: 'pieza')
    assert Unit.find_by(name: 'pliego')
    assert Unit.find_by(name: 'kg')
    assert Unit.find_by(name: 'millar')

    # Verify materials were created
    assert_equal 5, user.materials.count
    assert user.materials.find_by(description: 'Cartulina caple sulfatada 12 pts')
    assert user.materials.find_by(description: 'Cartulina caple sulfatada 14 pts')
    assert user.materials.find_by(description: 'Papel couché brillante 150 g/m²')
    assert user.materials.find_by(description: 'Cartón microcorrugado blanco')
    assert user.materials.find_by(description: 'Cartón gris (Backing)')

    # Verify manufacturing processes were created
    assert_equal 10, user.manufacturing_processes.count
    assert user.manufacturing_processes.find_by(name: 'Impresión offset 4 tintas (CMYK)')
    assert user.manufacturing_processes.find_by(name: 'Impresión Pantone (1 tinta)')
    assert user.manufacturing_processes.find_by(name: 'Barniz UV spot')
    assert user.manufacturing_processes.find_by(name: 'Laminado brillante')
    assert user.manufacturing_processes.find_by(name: 'Laminado mate')
    assert user.manufacturing_processes.find_by(name: 'Hot stamping')
    assert user.manufacturing_processes.find_by(name: 'Relieve seco (embossing)')
    assert user.manufacturing_processes.find_by(name: 'Troquelado')
    assert user.manufacturing_processes.find_by(name: 'Hendido y corte')
    assert user.manufacturing_processes.find_by(name: 'Pegado automático')

    # Verify extras were created
    assert_equal 7, user.extras.count
    assert user.extras.find_by(name: 'Fabricación de troquel')
    assert user.extras.find_by(name: 'Fabricación de placa offset (por tinta)')
    assert user.extras.find_by(name: 'Calibración de máquina impresora')
    assert user.extras.find_by(name: 'Calibración de troqueladora')
    assert user.extras.find_by(name: 'Desarrollo de muestra física (mockup)')
    assert user.extras.find_by(name: 'Diseño gráfico del empaque')
    assert user.extras.find_by(name: 'Supervisión de producción')

    # Verify price margins were created
    assert_equal 3, user.price_margins.count
    assert user.price_margins.find_by(min_price: 0, max_price: 5000)
    assert user.price_margins.find_by(min_price: 5001, max_price: 50000)
    assert user.price_margins.find_by(min_price: 50001, max_price: 200000)

    # Verify test product was created
    assert_equal 1, user.products.count
    test_product = user.products.first
    assert_equal "Caja plegadiza cosmética – cartulina caple 12 pts", test_product.description

    # Verify product data structure
    assert test_product.data.present?
    assert test_product.data["general_info"].present?
    assert test_product.data["materials"].present?
    assert test_product.data["processes"].present?
    assert test_product.data["extras"].present?
    assert test_product.data["pricing"].present?

    # Verify general info
    general_info = test_product.data["general_info"]
    assert_equal 32, general_info["width"]
    assert_equal 22, general_info["length"]
    assert_equal 1000, general_info["quantity"]
    assert_equal "Caja plegadiza cosmética – 4 tintas + barniz UV", general_info["comments"]

    # Verify materials in product
    materials = test_product.data["materials"]
    assert_equal 1, materials.length
    
    # Check material
    material = materials[0]
    assert material["material_id"].present?
    assert_equal "Cartulina caple sulfatada 12 pts para caja cosmética", material["comments"]
    assert_equal 1000, material["quantity"]
    assert_equal 6, material["piecesPerMaterial"]
    assert material["totalSheets"].present?
    assert material["totalSquareMeters"].present?
    assert material["totalPrice"].present?

    # Verify processes in product
    processes = test_product.data["processes"]
    assert_equal 5, processes.length
    
    # Check processes exist
    process_names = processes.map { |p| p["description"] }
    assert_includes process_names, "Impresión offset 4 tintas (CMYK)"
    assert_includes process_names, "Barniz UV spot"
    assert_includes process_names, "Troquelado"
    assert_includes process_names, "Hendido y corte"
    assert_includes process_names, "Pegado automático"

    # Verify extras in product
    extras = test_product.data["extras"]
    assert_equal 5, extras.length
    
    # Check extras exist
    extra_names = extras.map { |e| e["name"] }
    assert_includes extra_names, "Fabricación de troquel"
    assert_includes extra_names, "Fabricación de placa offset (por tinta)"
    assert_includes extra_names, "Calibración de máquina impresora"
    assert_includes extra_names, "Calibración de troqueladora"
    assert_includes extra_names, "Desarrollo de muestra física (mockup)"

    # Verify pricing structure exists
    pricing = test_product.data["pricing"]
    assert pricing["materials_cost"].present?
    assert pricing["processes_cost"].present?
    assert pricing["extras_cost"].present?
    assert_equal 5, pricing["waste_percentage"]
    assert_equal 10, pricing["margin_percentage"]
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
    kg_unit = Unit.find_by(name: 'kg')
    millar_unit = Unit.find_by(name: 'millar')

    assert_equal 'm²', mt2_unit.abbreviation
    assert_equal 'pieza', pieza_unit.abbreviation
    assert_equal 'pliego', pliego_unit.abbreviation
    assert_equal 'kg', kg_unit.abbreviation
    assert_equal 'millar', millar_unit.abbreviation
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
