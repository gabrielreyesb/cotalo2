#!/usr/bin/env ruby

# Debug script to understand why materials and processes costs are 0
require_relative 'config/environment'

puts "🔍 Debugging Product Calculation"
puts "=" * 50

# Find the test product
product = Product.find(202)
puts "Product: #{product.description}"

# Check what fields exist in materials
puts "\n📦 MATERIALS ANALYSIS:"
product.materials.each_with_index do |material, index|
  puts "Material #{index + 1}:"
  puts "  Fields: #{material.keys.join(', ')}"
  puts "  material_id: #{material['material_id']}"
  puts "  price: #{material['price']}"
  puts "  totalPrice: #{material['totalPrice']}"
  puts "  subtotal_price: #{material['subtotal_price']}"
  puts "  ancho: #{material['ancho']}"
  puts "  largo: #{material['largo']}"
  puts "  totalSheets: #{material['totalSheets']}"
  puts "  totalSquareMeters: #{material['totalSquareMeters']}"
end

# Check what fields exist in processes
puts "\n⚙️ PROCESSES ANALYSIS:"
product.processes.each_with_index do |process, index|
  puts "Process #{index + 1}:"
  puts "  Fields: #{process.keys.join(', ')}"
  puts "  process_id: #{process['process_id']}"
  puts "  unitPrice: #{process['unitPrice']}"
  puts "  price: #{process['price']}"
  puts "  subtotal_price: #{process['subtotal_price']}"
  puts "  veces: #{process['veces']}"
  puts "  unit: #{process['unit']}"
end

# Check what fields exist in extras
puts "\n➕ EXTRAS ANALYSIS:"
product.extras.each_with_index do |extra, index|
  puts "Extra #{index + 1}:"
  puts "  Fields: #{extra.keys.join(', ')}"
  puts "  extra_id: #{extra['extra_id']}"
  puts "  unit_price: #{extra['unit_price']}"
  puts "  total: #{extra['total']}"
  puts "  subtotal_price: #{extra['subtotal_price']}"
  puts "  quantity: #{extra['quantity']}"
end

# Test the calculate_totals method step by step
puts "\n🧮 CALCULATION DEBUG:"

# Test materials cost calculation
materials_cost = product.materials.sum do |m| 
  subtotal = m["subtotal_price"].to_f
  total_price = m["totalPrice"].to_f
  puts "  Material cost: subtotal_price(#{subtotal}) + totalPrice(#{total_price}) = #{subtotal + total_price}"
  subtotal + total_price
end
puts "  Total materials cost: #{materials_cost}"

# Test processes cost calculation
processes_cost = product.processes.sum do |p| 
  subtotal = p["subtotal_price"].to_f
  price = p["price"].to_f
  puts "  Process cost: subtotal_price(#{subtotal}) + price(#{price}) = #{subtotal + price}"
  subtotal + price
end
puts "  Total processes cost: #{processes_cost}"

# Test extras cost calculation
extras_cost = product.extras.sum do |e| 
  subtotal = e["subtotal_price"].to_f
  total = e["total"].to_f
  puts "  Extra cost: subtotal_price(#{subtotal}) + total(#{total}) = #{subtotal + total}"
  subtotal + total
end
puts "  Total extras cost: #{extras_cost}"

puts "\n🎯 CONCLUSION:"
puts "The problem is that materials and processes don't have calculated values in the expected fields."
puts "We need to either:"
puts "1. Calculate these values before calling calculate_totals"
puts "2. Modify calculate_totals to calculate these values"
puts "3. Use the existing fields that do have values" 