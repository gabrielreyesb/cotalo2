#!/usr/bin/env ruby

# Test script with improved calculate_totals method
require_relative 'config/environment'

puts "🔧 Testing Improved Product Calculation"
puts "=" * 50

# Find the test product
product = Product.find(202)
puts "Product: #{product.description}"

# Define an improved calculate_totals method
def improved_calculate_totals(product)
  puts "🧮 Calculating with improved method..."
  
  # Calculate materials cost
  materials_cost = 0
  product.materials.each_with_index do |material, index|
    material_id = material['material_id']
    material_record = product.user.materials.find_by(id: material_id)
    
    if material_record
      # Get product dimensions and quantity
      product_width = product.data['general_info']['width'].to_f
      product_length = product.data['general_info']['length'].to_f
      product_quantity = product.data['general_info']['quantity'].to_i
      
      # Calculate total square meters needed
      total_square_meters = (product_width * product_length * product_quantity) / 10000.0
      
      # Calculate material cost
      material_price = material_record.price.to_f
      material_cost = total_square_meters * material_price
      
      puts "  Material #{index + 1}: #{material_record.description}"
      puts "    - Product area: #{product_width} x #{product_length} cm = #{(product_width * product_length / 10000.0).round(4)} m² per piece"
      puts "    - Total area needed: #{total_square_meters.round(4)} m²"
      puts "    - Material price: $#{material_price}/m²"
      puts "    - Material cost: $#{material_cost.round(2)}"
      
      materials_cost += material_cost
    end
  end
  
  # Calculate processes cost
  processes_cost = 0
  product.processes.each_with_index do |process, index|
    process_id = process['process_id']
    process_record = product.user.manufacturing_processes.find_by(id: process_id)
    
    if process_record
      # Get product dimensions and quantity
      product_width = product.data['general_info']['width'].to_f
      product_length = product.data['general_info']['length'].to_f
      product_quantity = product.data['general_info']['quantity'].to_i
      
      # Calculate based on unit type
      process_price = process_record.cost.to_f
      veces = process['veces'].to_f
      
      if process_record.unit.abbreviation == 'm²'
        # Area-based process
        total_square_meters = (product_width * product_length * product_quantity) / 10000.0
        process_cost = total_square_meters * process_price * veces
        puts "  Process #{index + 1}: #{process_record.name} (m²-based)"
        puts "    - Total area: #{total_square_meters.round(4)} m²"
        puts "    - Process price: $#{process_price}/m²"
        puts "    - Veces: #{veces}"
        puts "    - Process cost: $#{process_cost.round(2)}"
      else
        # Piece-based process
        process_cost = product_quantity * process_price * veces
        puts "  Process #{index + 1}: #{process_record.name} (piece-based)"
        puts "    - Quantity: #{product_quantity} pieces"
        puts "    - Process price: $#{process_price}/piece"
        puts "    - Veces: #{veces}"
        puts "    - Process cost: $#{process_cost.round(2)}"
      end
      
      processes_cost += process_cost
    end
  end
  
  # Calculate extras cost (already calculated)
  extras_cost = product.extras.sum { |e| e['total'].to_f }
  puts "  Extras cost: $#{extras_cost}"
  
  # Calculate subtotal
  subtotal = materials_cost + processes_cost + extras_cost
  
  # Get waste percentage
  waste_pct = product.data['pricing']['waste_percentage'].to_f
  waste_value = subtotal * (waste_pct / 100.0)
  
  # Calculate price per piece before margin
  quantity = product.data['general_info']['quantity'].to_i
  price_per_piece_before_margin = (subtotal + waste_value) / quantity
  
  # Calculate margin
  margin_pct = product.data['pricing']['margin_percentage'].to_f
  margin_value = (subtotal + waste_value) * (margin_pct / 100.0)
  
  # Calculate total price
  total_price = subtotal + waste_value + margin_value
  final_price_per_piece = total_price / quantity
  
  # Update pricing data
  product.data['pricing'] = product.data['pricing'].merge(
    'materials_cost' => materials_cost,
    'processes_cost' => processes_cost,
    'extras_cost' => extras_cost,
    'subtotal' => subtotal,
    'waste_value' => waste_value,
    'price_per_piece_before_margin' => price_per_piece_before_margin,
    'margin_value' => margin_value,
    'total_price' => total_price,
    'final_price_per_piece' => final_price_per_piece
  )
  
  puts "\n📊 FINAL RESULTS:"
  puts "Materials cost: $#{materials_cost.round(2)}"
  puts "Processes cost: $#{processes_cost.round(2)}"
  puts "Extras cost: $#{extras_cost.round(2)}"
  puts "Subtotal: $#{subtotal.round(2)}"
  puts "Waste (#{waste_pct}%): $#{waste_value.round(2)}"
  puts "Subtotal with waste: $#{(subtotal + waste_value).round(2)}"
  puts "Margin (#{margin_pct}%): $#{margin_value.round(2)}"
  puts "TOTAL PRICE: $#{total_price.round(2)}"
  puts "Price per piece: $#{final_price_per_piece.round(4)}"
  
  return product
end

# Test the improved method
improved_product = improved_calculate_totals(product)

# Save the results
improved_product.save!

puts "\n✅ Product updated with improved calculations!"
puts "Product ID: #{improved_product.id}"
puts "You can view this product at: http://localhost:3000/products/#{improved_product.id}/edit" 