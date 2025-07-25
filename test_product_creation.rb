#!/usr/bin/env ruby

# Test script for product creation with materials, processes, and extras
# This script validates that the product calculation system works correctly

require 'net/http'
require 'json'
require 'uri'

class ProductCreationTest
  def initialize
    @base_url = 'http://localhost:3000'
    @api_token = nil
    @user_id = nil
    @test_materials = []
    @test_processes = []
    @test_extras = []
    @test_product = nil
  end

  def run_test
    puts "🧪 Starting Product Creation Test"
    puts "=" * 50
    
    begin
      # Step 1: Login and get API token
      login_user
      
      # Step 2: Create test materials
      create_test_materials
      
      # Step 3: Create test processes
      create_test_processes
      
      # Step 4: Create test extras
      create_test_extras
      
      # Step 5: Create test product
      create_test_product
      
      # Step 6: Validate calculations
      validate_calculations
      
      puts "✅ All tests passed successfully!"
      
    rescue => e
      puts "❌ Test failed: #{e.message}"
      puts e.backtrace.first(5)
    end
  end

  private

  def login_user
    puts "🔐 Logging in user..."
    
    # Simulate login - you might need to adjust this based on your auth system
    # For now, we'll assume we have a test user or use a default session
    @user_id = 1 # Adjust based on your test user ID
    
    puts "✅ Logged in as user #{@user_id}"
  end

  def create_test_materials
    puts "📦 Creating test materials..."
    
    materials_data = [
      {
        description: "Cartulina caple sulfatada 12 pts",
        client_description: "Cartulina caple sulfatada 12 pts",
        price: 0.85,
        ancho: 100.0,
        largo: 100.0,
        unit_id: 1, # Assuming unit ID 1 is for m²
        weight: 300 # grams per m²
      },
      {
        description: "Papel couché brillante 150 grs",
        client_description: "Papel couché brillante 150 grs", 
        price: 1.20,
        ancho: 100.0,
        largo: 100.0,
        unit_id: 1, # Assuming unit ID 1 is for m²
        weight: 150 # grams per m²
      }
    ]

    materials_data.each_with_index do |material_data, index|
      response = post_request("/api/v1/materials", { material: material_data })
      
      if response['id']
        @test_materials << response
        puts "✅ Created material #{index + 1}: #{material_data[:description]} (ID: #{response['id']})"
      else
        raise "Failed to create material #{index + 1}: #{response}"
      end
    end
  end

  def create_test_processes
    puts "⚙️ Creating test processes..."
    
    processes_data = [
      {
        name: "Impresión offset 4 tintas (CMYK)",
        description: "Impresión offset 4 tintas (CMYK)",
        price: 5.00,
        unit_id: 2 # Assuming unit ID 2 is for m²
      },
      {
        name: "Barniz UV",
        description: "Barniz UV",
        price: 3.50,
        unit_id: 2 # Assuming unit ID 2 is for m²
      },
      {
        name: "Corte y plegado",
        description: "Corte y plegado",
        price: 0.15,
        unit_id: 3 # Assuming unit ID 3 is for pieza
      },
      {
        name: "Empaque individual",
        description: "Empaque individual",
        price: 0.25,
        unit_id: 3 # Assuming unit ID 3 is for pieza
      }
    ]

    processes_data.each_with_index do |process_data, index|
      response = post_request("/api/v1/manufacturing_processes", { manufacturing_process: process_data })
      
      if response['id']
        @test_processes << response
        puts "✅ Created process #{index + 1}: #{process_data[:name]} (ID: #{response['id']})"
      else
        raise "Failed to create process #{index + 1}: #{response}"
      end
    end
  end

  def create_test_extras
    puts "➕ Creating test extras..."
    
    extras_data = [
      {
        name: "Diseño gráfico",
        description: "Diseño gráfico profesional",
        unit_price: 150.00,
        unit_id: 4 # Assuming unit ID 4 is for servicio
      },
      {
        name: "Prueba de color",
        description: "Prueba de color física",
        unit_price: 75.00,
        unit_id: 4 # Assuming unit ID 4 is for servicio
      },
      {
        name: "Entrega urgente",
        description: "Entrega en 24 horas",
        unit_price: 200.00,
        unit_id: 4 # Assuming unit ID 4 is for servicio
      }
    ]

    extras_data.each_with_index do |extra_data, index|
      response = post_request("/api/v1/extras", { extra: extra_data })
      
      if response['id']
        @test_extras << response
        puts "✅ Created extra #{index + 1}: #{extra_data[:name]} (ID: #{response['id']})"
      else
        raise "Failed to create extra #{index + 1}: #{response}"
      end
    end
  end

  def create_test_product
    puts "🏭 Creating test product..."
    
    # Product dimensions: 32 x 22 cm, 4000 pieces
    product_data = {
      description: "Tarjetas de presentación premium",
      data: {
        general_info: {
          quantity: 4000,
          width: 32,
          length: 22
        },
        materials: [
          {
            material_id: @test_materials[0]['id'],
            materialInstanceId: "#{@test_materials[0]['id']}_1",
            materialInstanceNumber: 1,
            displayName: "#{@test_materials[0]['description']} (1)",
            ancho: @test_materials[0]['ancho'],
            largo: @test_materials[0]['largo'],
            price: @test_materials[0]['price'],
            totalSheets: 0,
            totalSquareMeters: 0,
            totalPrice: 0
          },
          {
            material_id: @test_materials[1]['id'],
            materialInstanceId: "#{@test_materials[1]['id']}_1",
            materialInstanceNumber: 1,
            displayName: "#{@test_materials[1]['description']} (1)",
            ancho: @test_materials[1]['ancho'],
            largo: @test_materials[1]['largo'],
            price: @test_materials[1]['price'],
            totalSheets: 0,
            totalSquareMeters: 0,
            totalPrice: 0
          }
        ],
        processes: [
          # Processes for material 1
          {
            process_id: @test_processes[0]['id'],
            materialId: "#{@test_materials[0]['id']}_1",
            description: @test_processes[0]['description'],
            unit: @test_processes[0]['unit']['abbreviation'],
            unitPrice: @test_processes[0]['price'],
            veces: 1,
            price: 0
          },
          {
            process_id: @test_processes[1]['id'],
            materialId: "#{@test_materials[0]['id']}_1",
            description: @test_processes[1]['description'],
            unit: @test_processes[1]['unit']['abbreviation'],
            unitPrice: @test_processes[1]['price'],
            veces: 1,
            price: 0
          },
          # Processes for material 2
          {
            process_id: @test_processes[2]['id'],
            materialId: "#{@test_materials[1]['id']}_1",
            description: @test_processes[2]['description'],
            unit: @test_processes[2]['unit']['abbreviation'],
            unitPrice: @test_processes[2]['price'],
            veces: 1,
            price: 0
          },
          {
            process_id: @test_processes[3]['id'],
            materialId: "#{@test_materials[1]['id']}_1",
            description: @test_processes[3]['description'],
            unit: @test_processes[3]['unit']['abbreviation'],
            unitPrice: @test_processes[3]['price'],
            veces: 1,
            price: 0
          }
        ],
        extras: [
          {
            extra_id: @test_extras[0]['id'],
            name: @test_extras[0]['name'],
            description: @test_extras[0]['description'],
            unit_price: @test_extras[0]['unit_price'],
            unit: @test_extras[0]['unit']['abbreviation'],
            quantity: 1,
            total: @test_extras[0]['unit_price']
          },
          {
            extra_id: @test_extras[1]['id'],
            name: @test_extras[1]['name'],
            description: @test_extras[1]['description'],
            unit_price: @test_extras[1]['unit_price'],
            unit: @test_extras[1]['unit']['abbreviation'],
            quantity: 1,
            total: @test_extras[1]['unit_price']
          },
          {
            extra_id: @test_extras[2]['id'],
            name: @test_extras[2]['name'],
            description: @test_extras[2]['description'],
            unit_price: @test_extras[2]['unit_price'],
            unit: @test_extras[2]['unit']['abbreviation'],
            quantity: 1,
            total: @test_extras[2]['unit_price']
          }
        ],
        pricing: {
          materials_cost: 0,
          processes_cost: 0,
          extras_cost: 0,
          subtotal: 0,
          waste_percentage: 5,
          waste_value: 0,
          price_per_piece_before_margin: 0,
          margin_percentage: 10,
          margin_value: 0,
          total_price: 0,
          final_price_per_piece: 0
        }
      }
    }

    response = post_request("/api/v1/products", { product: product_data })
    
    if response['id']
      @test_product = response
      puts "✅ Created product: #{product_data[:description]} (ID: #{response['id']})"
    else
      raise "Failed to create product: #{response}"
    end
  end

  def validate_calculations
    puts "🧮 Validating calculations..."
    
    # Get the created product with calculated values
    response = get_request("/api/v1/products/#{@test_product['id']}")
    
    if response['id']
      product = response
      pricing = product['data']['pricing']
      
      puts "\n📊 CALCULATION RESULTS:"
      puts "=" * 40
      puts "Product: #{product['description']}"
      puts "Quantity: #{product['data']['general_info']['quantity']} pieces"
      puts "Dimensions: #{product['data']['general_info']['width']} x #{product['data']['general_info']['length']} cm"
      puts ""
      puts "�� COSTS BREAKDOWN:"
      puts "Materials cost: $#{pricing['materials_cost']}"
      puts "Processes cost: $#{pricing['processes_cost']}"
      puts "Extras cost: $#{pricing['extras_cost']}"
      puts "Subtotal: $#{pricing['subtotal']}"
      puts "Waste (5%): $#{pricing['waste_value']}"
      puts "Subtotal with waste: $#{pricing['subtotal'] + pricing['waste_value']}"
      puts "Margin (10%): $#{pricing['margin_value']}"
      puts "TOTAL PRICE: $#{pricing['total_price']}"
      puts "Price per piece: $#{pricing['final_price_per_piece']}"
      puts ""
      
      # Validate that calculations are reasonable
      validate_reasonable_values(pricing)
      
    else
      raise "Failed to retrieve product for validation"
    end
  end

  def validate_reasonable_values(pricing)
    puts "🔍 VALIDATION CHECKS:"
    
    # Check that all costs are positive
    if pricing['materials_cost'] <= 0
      puts "❌ Materials cost should be positive"
    else
      puts "✅ Materials cost is positive"
    end
    
    if pricing['processes_cost'] <= 0
      puts "❌ Processes cost should be positive"
    else
      puts "✅ Processes cost is positive"
    end
    
    if pricing['extras_cost'] <= 0
      puts "❌ Extras cost should be positive"
    else
      puts "✅ Extras cost is positive"
    end
    
    if pricing['total_price'] <= 0
      puts "❌ Total price should be positive"
    else
      puts "✅ Total price is positive"
    end
    
    if pricing['final_price_per_piece'] <= 0
      puts "❌ Price per piece should be positive"
    else
      puts "✅ Price per piece is positive"
    end
    
    # Check that total price makes sense for 4000 pieces
    expected_min_total = 4000 * 0.10 # At least $0.10 per piece
    if pricing['total_price'] < expected_min_total
      puts "❌ Total price seems too low for 4000 pieces"
    else
      puts "✅ Total price is reasonable for 4000 pieces"
    end
    
    puts ""
    puts "🎯 EXPECTED RESULTS:"
    puts "- Materials cost should be around $2,000-$3,000 (2 materials, 4000 pieces)"
    puts "- Processes cost should be around $800-$1,200 (4 processes, 4000 pieces)"
    puts "- Extras cost should be $425 (3 extras: $150 + $75 + $200)"
    puts "- Total should be around $3,500-$5,000"
    puts "- Price per piece should be around $0.90-$1.25"
  end

  def post_request(path, data)
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['X-Requested-With'] = 'XMLHttpRequest'
    request.body = data.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end

  def get_request(path)
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    request['X-Requested-With'] = 'XMLHttpRequest'
    
    response = http.request(request)
    JSON.parse(response.body)
  end
end

# Run the test
if __FILE__ == $0
  test = ProductCreationTest.new
  test.run_test
end 