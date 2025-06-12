require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    
    # Create test units
    @mt2_unit = Unit.find_or_create_by!(name: 'mt2', abbreviation: 'm²')
    @pieza_unit = Unit.find_or_create_by!(name: 'pieza', abbreviation: 'pieza')
    @pliego_unit = Unit.find_or_create_by!(name: 'pliego', abbreviation: 'pliego')
    
    # Create test materials
    @material1 = @user.materials.create!(
      description: 'Caple 12 puntos',
      client_description: 'Caple',
      price: 10,
      unit: @mt2_unit,
      ancho: 100,
      largo: 100
    )
    
    @material2 = @user.materials.create!(
      description: 'Cartulina multicapa 14 pts',
      client_description: 'Cartulina multicapa',
      price: 12,
      unit: @mt2_unit,
      ancho: 100,
      largo: 100
    )
    
    # Create test processes
    @process1 = @user.manufacturing_processes.create!(
      name: 'Empalmado',
      description: '',
      cost: 3.50,
      unit: @mt2_unit
    )
    
    @process2 = @user.manufacturing_processes.create!(
      name: 'Pegado lineal',
      description: '',
      cost: 0.35,
      unit: @pieza_unit
    )
    
    # Create test extras
    @extra1 = @user.extras.create!(
      name: 'Placas de impresión 4 oficios',
      description: '',
      cost: 250,
      unit: @pieza_unit
    )
    
    # Create price margins
    @user.price_margins.create!([
      { min_price: 0, max_price: 5000, margin_percentage: 10 },
      { min_price: 5001, max_price: 50000, margin_percentage: 15 },
      { min_price: 50001, max_price: 200000, margin_percentage: 25 }
    ])
  end

  test "should create product with valid data" do
    product = @user.products.create!(
      description: "Test Product",
      data: {
        general_info: {
          width: 50,
          length: 30,
          quantity: 100,
          comments: "Test product"
        },
        materials: [
          {
            material_id: @material1.id,
            description: @material1.description,
            client_description: @material1.client_description,
            price: @material1.price,
            unit: {
              id: @material1.unit.id,
              name: @material1.unit.name,
              abbreviation: @material1.unit.abbreviation
            },
            width: 50,
            length: 30,
            quantity: 100,
            pieces_per_material: 6,
            total_sheets: 17,
            total_square_meters: 25.5,
            subtotal_price: 255.0,
            comments: "Main material"
          }
        ],
        processes: [],
        extras: [],
        pricing: {
          materials_cost: 255.0,
          processes_cost: 0,
          extras_cost: 0,
          subtotal: 255.0,
          waste_percentage: 5,
          waste_value: 12.75,
          price_per_piece_before_margin: 2.68,
          margin_percentage: 10,
          margin_value: 26.78,
          total_price: 294.53,
          final_price_per_piece: 2.95
        }
      }
    )
    
    assert product.persisted?
    assert_equal "Test Product", product.description
    assert_equal 1, product.materials.count
    assert_equal 0, product.processes.count
    assert_equal 0, product.extras.count
    assert_equal 294.53, product.pricing["total_price"]
  end

  test "should validate presence of description" do
    product = @user.products.build(description: nil)
    assert_not product.valid?
    assert_includes product.errors[:description], "can't be blank"
  end

  test "should validate presence of user" do
    product = Product.build(description: "Test", user: nil)
    assert_not product.valid?
    assert_includes product.errors[:user], "must exist"
  end

  test "should validate general info structure" do
    product = @user.products.build(
      description: "Test",
      data: { general_info: nil }
    )
    assert_not product.valid?
  end

  test "should validate materials presence" do
    product = @user.products.build(
      description: "Test",
      data: { materials: [] }
    )
    assert_not product.valid?
  end

  test "should calculate totals correctly" do
    product = @user.products.create!(
      description: "Test Product",
      data: {
        general_info: {
          width: 50,
          length: 30,
          quantity: 100,
          comments: "Test product"
        },
        materials: [
          {
            material_id: @material1.id,
            description: @material1.description,
            client_description: @material1.client_description,
            price: @material1.price,
            unit: {
              id: @material1.unit.id,
              name: @material1.unit.name,
              abbreviation: @material1.unit.abbreviation
            },
            width: 50,
            length: 30,
            quantity: 100,
            pieces_per_material: 6,
            total_sheets: 17,
            total_square_meters: 25.5,
            subtotal_price: 255.0,
            comments: "Main material"
          }
        ],
        processes: [
          {
            process_id: @process1.id,
            description: @process1.name,
            price: @process1.cost,
            unit: {
              id: @process1.unit.id,
              name: @process1.unit.name,
              abbreviation: @process1.unit.abbreviation
            },
            quantity: 25.5,
            subtotal_price: 89.25,
            comments: "Main process"
          }
        ],
        extras: [
          {
            extra_id: @extra1.id,
            description: @extra1.name,
            price: @extra1.cost,
            quantity: 1,
            subtotal_price: 250.0,
            comments: "Printing plates"
          }
        ],
        pricing: {
          materials_cost: 255.0,
          processes_cost: 89.25,
          extras_cost: 250.0,
          subtotal: 594.25,
          waste_percentage: 5,
          waste_value: 29.71,
          price_per_piece_before_margin: 6.24,
          margin_percentage: 10,
          margin_value: 62.40,
          total_price: 686.36,
          final_price_per_piece: 6.86
        }
      }
    )
    
    product.calculate_totals
    
    assert_equal 255.0, product.pricing["materials_cost"]
    assert_equal 89.25, product.pricing["processes_cost"]
    assert_equal 250.0, product.pricing["extras_cost"]
    assert_equal 594.25, product.pricing["subtotal"]
    assert_equal 686.36, product.pricing["total_price"]
  end

  test "should add material correctly" do
    product = @user.products.create!(description: "Test Product")
    
    product.add_material(@material1.id, {
      width: 50,
      length: 30,
      quantity: 100,
      comments: "Added material"
    })
    
    assert_equal 1, product.materials.count
    assert_equal @material1.id, product.materials.first["material_id"]
    assert_equal "Added material", product.materials.first["comments"]
  end

  test "should add process correctly" do
    product = @user.products.create!(description: "Test Product")
    
    product.add_process(@process1.id, {
      quantity: 25.5,
      comments: "Added process"
    })
    
    assert_equal 1, product.processes.count
    assert_equal @process1.id, product.processes.first["process_id"]
    assert_equal "Added process", product.processes.first["comments"]
  end

  test "should add extra correctly" do
    product = @user.products.create!(description: "Test Product")
    
    product.add_extra(@extra1.id, {
      quantity: 1,
      comments: "Added extra"
    })
    
    assert_equal 1, product.extras.count
    assert_equal @extra1.id, product.extras.first["extra_id"]
    assert_equal "Added extra", product.extras.first["comments"]
  end

  test "should remove material correctly" do
    product = @user.products.create!(description: "Test Product")
    product.add_material(@material1.id)
    product.add_material(@material2.id)
    
    assert_equal 2, product.materials.count
    
    product.remove_material(@material1.id)
    
    assert_equal 1, product.materials.count
    assert_equal @material2.id, product.materials.first["material_id"]
  end

  test "should deep clone product" do
    product = @user.products.create!(
      description: "Original Product",
      data: {
        general_info: { width: 50, length: 30, quantity: 100 },
        materials: [
          {
            material_id: @material1.id,
            description: @material1.description,
            price: @material1.price,
            unit: { id: @material1.unit.id, name: @material1.unit.name, abbreviation: @material1.unit.abbreviation },
            width: 50,
            length: 30,
            quantity: 100,
            pieces_per_material: 6,
            total_sheets: 17,
            total_square_meters: 25.5,
            subtotal_price: 255.0
          }
        ],
        processes: [],
        extras: [],
        pricing: { total_price: 255.0 }
      }
    )
    
    cloned_product = product.deep_clone
    
    assert_equal "Original Product (Copia)", cloned_product.description
    assert_equal product.materials.count, cloned_product.materials.count
    assert_equal product.pricing["total_price"], cloned_product.pricing["total_price"]
    assert_not_equal product.id, cloned_product.id
  end

  test "should format description with price" do
    product = @user.products.create!(
      description: "Test Product",
      data: { pricing: { total_price: 123.45 } }
    )
    
    assert_equal "Test Product - $123.45", product.formatted_description
  end

  test "should calculate margin percentage based on price ranges" do
    product = @user.products.create!(description: "Test Product")
    
    # Test different price ranges
    assert_equal 10, product.calculate_margin_percentage(1000)  # 0-5000 range
    assert_equal 15, product.calculate_margin_percentage(10000) # 5001-50000 range
    assert_equal 25, product.calculate_margin_percentage(100000) # 50001-200000 range
  end
end 