#!/usr/bin/env ruby

# Script to check material data in production
puts "🔍 Checking material data in production"
puts "=" * 50

# Find the Bond material
bond_material = Material.find_by(description: 'Papel bond 90 g/m²')
if bond_material.nil?
  puts "❌ Bond material not found in production"
  exit
end

puts "Material: #{bond_material.description}"
puts "ID: #{bond_material.id}"
puts "Price: $#{bond_material.price}"
puts "Unit: #{bond_material.unit&.name}"
puts "Dimensions: #{bond_material.ancho}cm × #{bond_material.largo}cm"
puts "Weight: #{bond_material.weight || 'Not defined'}"

# Check if there are any users with this material
users_with_material = User.joins(:materials).where(materials: { id: bond_material.id })
puts "\nUsers with this material: #{users_with_material.count}"

if users_with_material.count > 0
  user = users_with_material.first
  puts "First user: #{user.email}"
  
  # Check recent products for this user
  recent_products = user.products.order(created_at: :desc).limit(5)
  puts "\nRecent products:"
  recent_products.each do |product|
    puts "- Product ID: #{product.id}"
    puts "  Description: #{product.description}"
    puts "  Created: #{product.created_at}"
    puts "  Materials count: #{product.data['materials']&.count || 0}"
    
    if product.data['materials']&.any?
      product.data['materials'].each_with_index do |material, index|
        puts "  Material #{index + 1}:"
        puts "    ID: #{material['id']}"
        puts "    Description: #{material['description']}"
        puts "    Price: $#{material['price']}"
        puts "    Width: #{material['width']}cm"
        puts "    Length: #{material['length']}cm"
        puts "    Quantity: #{material['quantity']}"
        puts "    Pieces per material: #{material['pieces_per_material']}"
        puts "    Total sheets: #{material['total_sheets']}"
        puts "    Total square meters: #{material['total_square_meters']}"
        puts "    Subtotal price: $#{material['subtotal_price']}"
      end
    end
    puts ""
  end
end

puts "✅ Production data check completed" 