#!/usr/bin/env ruby

# Test script to verify Bond material calculation
require_relative 'config/environment'

puts "🧪 Testing Bond Material Calculation"
puts "=" * 50

# Find the Bond material
bond_material = Material.find_by(description: 'Papel bond 90 g/m²')
puts "Material: #{bond_material.description}"
puts "Unit: #{bond_material.unit&.name}"
puts "Price: $#{bond_material.price}/m²"
puts "Weight: #{bond_material.weight || 'Not defined'}"
puts "Dimensions: #{bond_material.ancho}cm × #{bond_material.largo}cm"

# Test calculation with the scenario from the image
product_quantity = 3000
product_width = 32
product_length = 22
material_width = 70  # Modified by user in interface
material_length = 50  # Modified by user in interface
user_price = 2.12  # Price modified by user

puts "\n📐 Calculation Details:"
puts "Product: #{product_quantity} pieces of #{product_width}cm × #{product_length}cm"
puts "Material: #{material_width}cm × #{material_length}cm"
puts "User price: $#{user_price}/m²"

# Calculate pieces per material
pieces_per_material = 4  # From the image
puts "Pieces per material: #{pieces_per_material}"

# Calculate total sheets needed
total_sheets = (product_quantity.to_f / pieces_per_material).ceil
puts "Total sheets needed: #{total_sheets}"

# Calculate total square meters
total_square_meters = total_sheets * (material_width * material_length) / 10000.0
puts "Total square meters: #{total_square_meters}"

# Calculate expected price
expected_price = total_square_meters * user_price
puts "Expected price: $#{expected_price}"

# Calculate what would give us $1,590.00
factor = 1590.0 / expected_price
puts "Factor to reach $1,590.00: #{factor}"

# Check if there's a weight calculation involved
if bond_material.weight.present?
  total_weight = total_square_meters * bond_material.weight
  weight_price = total_weight * user_price
  puts "Weight-based calculation: #{total_weight}g × $#{user_price} = $#{weight_price}"
end

puts "\n🔍 Possible causes for the discrepancy:"
puts "1. Material has weight defined: #{bond_material.weight.present?}"
puts "2. Unit type detection issue: #{bond_material.unit&.name&.downcase&.include?('grs/m2')}"
puts "3. Frontend calculation error"
puts "4. Backend calculation error"

# Test the actual calculation method
puts "\n🧮 Testing actual calculation method:"
puts "Material ID: #{bond_material.id}"
puts "Material found in DB: #{Material.find_by(id: bond_material.id).present?}"
user = User.first
puts "User materials: #{user.materials.where(id: bond_material.id).count}"

# Check if material is associated with user, if not, associate it
if user.materials.where(id: bond_material.id).count == 0
  puts "Material not associated with user. Associating..."
  user.materials << bond_material
  puts "Material associated. User materials count: #{user.materials.where(id: bond_material.id).count}"
end

# Create test material data
test_material = {
  "material_id" => bond_material.id,
  "width" => product_width,
  "length" => product_length,
  "quantity" => product_quantity,
  "pieces_per_material" => pieces_per_material,
  "price" => user_price,
  "ancho" => material_width,  # Material dimensions modified by user
  "largo" => material_length  # Material dimensions modified by user
}

# Create a test product
user = User.first
test_product = Product.new(user: user, description: "Test Product")
test_product.data = {
  "general_info" => {
    "quantity" => product_quantity,
    "width" => product_width,
    "length" => product_length
  },
  "materials" => [],
  "pricing" => {
    "materials_cost" => 0,
    "processes_cost" => 0,
    "extras_cost" => 0,
    "subtotal" => 0,
    "waste_percentage" => 5,
    "waste_value" => 0,
    "price_per_piece_before_margin" => 0,
    "margin_percentage" => 10,
    "margin_value" => 0,
    "total_price" => 0,
    "final_price_per_piece" => 0
  }
}

# Add material using the public method
puts "\n📊 Adding material using public method..."
test_product.add_material(bond_material.id, {
  "width" => product_width,
  "length" => product_length,
  "quantity" => product_quantity,
  "pieces_per_material" => pieces_per_material,
  "price" => user_price,
  "ancho" => material_width,
  "largo" => material_length
})

puts "Material added: #{test_product.materials.first.inspect}"

# Now calculate totals
puts "\n🧮 Calculating totals..."
test_product.calculate_totals
cost = test_product.pricing["materials_cost"]
puts "Backend calculation result: $#{cost}"
puts "Pricing data: #{test_product.pricing.inspect}"

puts "\n✅ Test completed!" 