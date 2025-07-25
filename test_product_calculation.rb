#!/usr/bin/env ruby

# Simple Rails script to test product calculation
# Run with: rails runner test_product_calculation.rb

puts "🧪 Testing Product Calculation System"
puts "=" * 50

# Find or create a test user
user = User.first || User.create!(email: 'test@example.com', password: 'password123')

puts "👤 Using user: #{user.email}"

# Clean up any existing test data
puts "🧹 Cleaning up existing test data..."
user.products.where(description: 'Tarjetas de presentación premium').destroy_all
user.materials.where(description: ['Cartulina caple sulfatada 12 pts', 'Papel couché brillante 150 grs']).destroy_all
user.manufacturing_processes.where(name: ['Impresión offset 4 tintas (CMYK)', 'Barniz UV', 'Corte y plegado', 'Empaque individual']).destroy_all
user.extras.where(name: ['Diseño gráfico', 'Prueba de color', 'Entrega urgente']).destroy_all

# Get existing units
m2_unit = Unit.find_by(abbreviation: 'm²')
pieza_unit = Unit.find_by(abbreviation: 'pieza')
servicio_unit = Unit.find_by(abbreviation: 'servicio')

puts "📏 Found units:"
puts "  - m²: ID #{m2_unit.id}" if m2_unit
puts "  - pieza: ID #{pieza_unit.id}" if pieza_unit
puts "  - servicio: ID #{servicio_unit.id}" if servicio_unit

puts "📏 Units ready"

# Create test materials
puts "📦 Creating test materials..."

material1 = user.materials.create!(
  description: "Cartulina caple sulfatada 12 pts",
  client_description: "Cartulina caple sulfatada 12 pts",
  price: 0.85,
  ancho: 100.0,
  largo: 100.0,
  unit: m2_unit,
  weight: 300
)

material2 = user.materials.create!(
  description: "Papel couché brillante 150 grs",
  client_description: "Papel couché brillante 150 grs",
  price: 1.20,
  ancho: 100.0,
  largo: 100.0,
  unit: m2_unit,
  weight: 150
)

puts "✅ Materials created: #{material1.description}, #{material2.description}"

# Create test processes
puts "⚙️ Creating test processes..."

process1 = user.manufacturing_processes.create!(
  name: "Impresión offset 4 tintas (CMYK)",
  description: "Impresión offset 4 tintas (CMYK)",
  cost: 5.00,
  unit: m2_unit
)

process2 = user.manufacturing_processes.create!(
  name: "Barniz UV",
  description: "Barniz UV",
  cost: 3.50,
  unit: m2_unit
)

process3 = user.manufacturing_processes.create!(
  name: "Corte y plegado",
  description: "Corte y plegado",
  cost: 0.15,
  unit: pieza_unit
)

process4 = user.manufacturing_processes.create!(
  name: "Empaque individual",
  description: "Empaque individual",
  cost: 0.25,
  unit: pieza_unit
)

puts "✅ Processes created: #{process1.name}, #{process2.name}, #{process3.name}, #{process4.name}"

# Create test extras
puts "➕ Creating test extras..."

extra1 = user.extras.create!(
  name: "Diseño gráfico",
  description: "Diseño gráfico profesional",
  cost: 150.00,
  unit: servicio_unit
)

extra2 = user.extras.create!(
  name: "Prueba de color",
  description: "Prueba de color física",
  cost: 75.00,
  unit: servicio_unit
)

extra3 = user.extras.create!(
  name: "Entrega urgente",
  description: "Entrega en 24 horas",
  cost: 200.00,
  unit: servicio_unit
)

puts "✅ Extras created: #{extra1.name}, #{extra2.name}, #{extra3.name}"

# Create test product
puts "🏭 Creating test product..."

product = user.products.create!(
  description: "Tarjetas de presentación premium",
  data: {
    general_info: {
      quantity: 4000,
      width: 32,
      length: 22
    },
    materials: [
      {
        material_id: material1.id,
        materialInstanceId: "#{material1.id}_1",
        materialInstanceNumber: 1,
        displayName: "#{material1.description} (1)",
        ancho: material1.ancho,
        largo: material1.largo,
        price: material1.price,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0
      },
      {
        material_id: material2.id,
        materialInstanceId: "#{material2.id}_1",
        materialInstanceNumber: 1,
        displayName: "#{material2.description} (1)",
        ancho: material2.ancho,
        largo: material2.largo,
        price: material2.price,
        totalSheets: 0,
        totalSquareMeters: 0,
        totalPrice: 0
      }
    ],
    processes: [
      # Processes for material 1
      {
        process_id: process1.id,
        materialId: "#{material1.id}_1",
        description: process1.description,
        unit: process1.unit.abbreviation,
        unitPrice: process1.cost,
        veces: 1,
        price: 0
      },
      {
        process_id: process2.id,
        materialId: "#{material1.id}_1",
        description: process2.description,
        unit: process2.unit.abbreviation,
        unitPrice: process2.cost,
        veces: 1,
        price: 0
      },
      # Processes for material 2
      {
        process_id: process3.id,
        materialId: "#{material2.id}_1",
        description: process3.description,
        unit: process3.unit.abbreviation,
        unitPrice: process3.cost,
        veces: 1,
        price: 0
      },
      {
        process_id: process4.id,
        materialId: "#{material2.id}_1",
        description: process4.description,
        unit: process4.unit.abbreviation,
        unitPrice: process4.cost,
        veces: 1,
        price: 0
      }
    ],
    extras: [
      {
        extra_id: extra1.id,
        name: extra1.name,
        description: extra1.description,
        unit_price: extra1.cost,
        unit: extra1.unit.abbreviation,
        quantity: 1,
        total: extra1.cost
      },
      {
        extra_id: extra2.id,
        name: extra2.name,
        description: extra2.description,
        unit_price: extra2.cost,
        unit: extra2.unit.abbreviation,
        quantity: 1,
        total: extra2.cost
      },
      {
        extra_id: extra3.id,
        name: extra3.name,
        description: extra3.description,
        unit_price: extra3.cost,
        unit: extra3.unit.abbreviation,
        quantity: 1,
        total: extra3.cost
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
)

puts "✅ Product created: #{product.description}"

# Calculate totals
puts "🧮 Calculating totals..."
product.calculate_totals
product.save!

# Display results
pricing = product.data['pricing']

puts "\n📊 CALCULATION RESULTS:"
puts "=" * 40
puts "Product: #{product.description}"
puts "Quantity: #{product.data['general_info']['quantity']} pieces"
puts "Dimensions: #{product.data['general_info']['width']} x #{product.data['general_info']['length']} cm"
puts ""
puts "💰 COSTS BREAKDOWN:"
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

# Validation checks
puts "🔍 VALIDATION CHECKS:"
puts "✅ Materials cost is positive: $#{pricing['materials_cost']}" if pricing['materials_cost'] > 0
puts "✅ Processes cost is positive: $#{pricing['processes_cost']}" if pricing['processes_cost'] > 0
puts "✅ Extras cost is positive: $#{pricing['extras_cost']}" if pricing['extras_cost'] > 0
puts "✅ Total price is positive: $#{pricing['total_price']}" if pricing['total_price'] > 0
puts "✅ Price per piece is positive: $#{pricing['final_price_per_piece']}" if pricing['final_price_per_piece'] > 0

expected_min_total = 4000 * 0.10
if pricing['total_price'] >= expected_min_total
  puts "✅ Total price is reasonable for 4000 pieces"
else
  puts "❌ Total price seems too low for 4000 pieces"
end

puts ""
puts "🎯 EXPECTED RESULTS:"
puts "- Materials cost should be around $2,000-$3,000 (2 materials, 4000 pieces)"
puts "- Processes cost should be around $800-$1,200 (4 processes, 4000 pieces)"
puts "- Extras cost should be $425 (3 extras: $150 + $75 + $200)"
puts "- Total should be around $3,500-$5,000"
puts "- Price per piece should be around $0.90-$1.25"

puts ""
puts "🎉 Test completed successfully!"
puts "Product ID: #{product.id}"
puts "You can view this product in the web interface at: http://localhost:3000/products/#{product.id}/edit" 