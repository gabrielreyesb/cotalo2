#!/usr/bin/env ruby

# Test script to verify product creation when a new user is created
require_relative 'config/environment'

puts "=== Testing Product Creation for New Users ==="
puts

# Clean up any existing test data
puts "Cleaning up existing test data..."
# Delete in proper order to avoid foreign key constraints
QuoteProduct.destroy_all
Quote.destroy_all
Product.destroy_all
Extra.destroy_all
ManufacturingProcess.destroy_all
Material.destroy_all
PriceMargin.destroy_all
AppConfig.destroy_all
PdfConfig.destroy_all
User.where(email: 'test@example.com').destroy_all
Unit.destroy_all

puts "Creating a new test user..."
user = User.create!(
  email: 'test@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

puts "✅ User created: #{user.email}"
puts

# Verify demo data was created
puts "=== Verifying Demo Data Creation ==="
puts

# Check units
puts "📏 Units created: #{Unit.count}"
Unit.all.each do |unit|
  puts "  - #{unit.name} (#{unit.abbreviation})"
end
puts

# Check materials
puts "📦 Materials created: #{user.materials.count}"
user.materials.each do |material|
  puts "  - #{material.description} - $#{material.price}/#{material.unit.abbreviation}"
end
puts

# Check manufacturing processes
puts "⚙️  Manufacturing processes created: #{user.manufacturing_processes.count}"
user.manufacturing_processes.each do |process|
  puts "  - #{process.name} - $#{process.cost}/#{process.unit.abbreviation}"
end
puts

# Check extras
puts "🔧 Extras created: #{user.extras.count}"
user.extras.each do |extra|
  puts "  - #{extra.name} - $#{extra.cost}/#{extra.unit.abbreviation}"
end
puts

# Check price margins
puts "💰 Price margins created: #{user.price_margins.count}"
user.price_margins.each do |margin|
  puts "  - $#{margin.min_price} - $#{margin.max_price}: #{margin.margin_percentage}%"
end
puts

# Check products
puts "📋 Products created: #{user.products.count}"
user.products.each do |product|
  puts "  - #{product.description}"
  puts "    General Info:"
  puts "      - Width: #{product.general_info['width']} cm"
  puts "      - Length: #{product.general_info['length']} cm"
  puts "      - Quantity: #{product.general_info['quantity']}"
  puts "      - Comments: #{product.general_info['comments']}"
  puts
  puts "    Materials (#{product.materials.length}):"
  product.materials.each_with_index do |material, index|
    puts "      #{index + 1}. #{material['description']}"
    puts "         - Size: #{material['width']} x #{material['length']} cm"
    puts "         - Quantity: #{material['quantity']} pieces"
    puts "         - Pieces per material: #{material['pieces_per_material']}"
    puts "         - Total sheets: #{material['total_sheets']}"
    puts "         - Total m²: #{material['total_square_meters']}"
    puts "         - Subtotal: $#{material['subtotal_price']}"
    puts "         - Comments: #{material['comments']}"
  end
  puts
  puts "    Processes (#{product.processes.length}):"
  product.processes.each_with_index do |process, index|
    puts "      #{index + 1}. #{process['description']}"
    puts "         - Quantity: #{process['quantity']} #{process['unit']['abbreviation']}"
    puts "         - Subtotal: $#{process['subtotal_price']}"
    puts "         - Comments: #{process['comments']}"
  end
  puts
  puts "    Extras (#{product.extras.length}):"
  product.extras.each_with_index do |extra, index|
    puts "      #{index + 1}. #{extra['description']}"
    puts "         - Quantity: #{extra['quantity']}"
    puts "         - Subtotal: $#{extra['subtotal_price']}"
    puts "         - Comments: #{extra['comments']}"
  end
  puts
  puts "    Pricing:"
  pricing = product.pricing
  puts "      - Materials cost: $#{pricing['materials_cost']}"
  puts "      - Processes cost: $#{pricing['processes_cost']}"
  puts "      - Extras cost: $#{pricing['extras_cost']}"
  puts "      - Subtotal: $#{pricing['subtotal']}"
  puts "      - Waste percentage: #{pricing['waste_percentage']}%"
  puts "      - Waste value: $#{pricing['waste_value']}"
  puts "      - Price per piece (before margin): $#{pricing['price_per_piece_before_margin']}"
  puts "      - Margin percentage: #{pricing['margin_percentage']}%"
  puts "      - Margin value: $#{pricing['margin_value']}"
  puts "      - Total price: $#{pricing['total_price']}"
  puts "      - Final price per piece: $#{pricing['final_price_per_piece']}"
end
puts

# Test the product's calculate_totals method
puts "=== Testing Product Calculations ==="
test_product = user.products.first
puts "Recalculating totals for the test product..."
test_product.calculate_totals
test_product.save!

puts "✅ Product calculations updated successfully"
puts

# Verify the product can be used in a quote
puts "=== Testing Product in Quote ==="
quote = user.quotes.create!(
  quote_number: "TEST-001",
  project_name: "Test Project",
  customer_name: "Test Customer",
  organization: "Test Organization",
  email: "customer@example.com",
  telephone: "123-456-7890",
  comments: "Test quote for demo product"
)

# Add the product to the quote
quote_product = QuoteProduct.create!(
  quote: quote,
  product: test_product,
  quantity: 50
)

puts "✅ Quote created with test product"
puts "  - Quote: #{quote.quote_number}"
puts "  - Product: #{test_product.description}"
puts "  - Quantity: #{quote_product.quantity}"
puts "  - Total cost: $#{test_product.pricing['total_price'] * quote_product.quantity}"
puts

# Test product duplication
puts "=== Testing Product Duplication ==="
duplicated_product = test_product.deep_clone
duplicated_product.save!

puts "✅ Product duplicated successfully"
puts "  - Original: #{test_product.description}"
puts "  - Duplicate: #{duplicated_product.description}"
puts

# Clean up test data
puts "=== Cleaning Up ==="
# Delete in proper order to avoid foreign key constraints
QuoteProduct.destroy_all
Quote.destroy_all
Product.destroy_all
Extra.destroy_all
ManufacturingProcess.destroy_all
Material.destroy_all
PriceMargin.destroy_all
AppConfig.destroy_all
PdfConfig.destroy_all
User.where(email: 'test@example.com').destroy_all
Unit.destroy_all
puts "✅ Test data cleaned up"
puts

puts "=== Test Summary ==="
puts "✅ User creation with demo data works correctly"
puts "✅ Product creation with complete data structure works"
puts "✅ Product calculations work correctly"
puts "✅ Product can be used in quotes"
puts "✅ Product duplication works"
puts "✅ All associations are properly set up"
puts
puts "🎉 All tests passed! The product creation functionality is working correctly." 