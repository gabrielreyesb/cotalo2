#!/usr/bin/env ruby

# Script to check material data in Heroku production
puts "🔍 Checking material data in Heroku production"
puts "=" * 50

# Find the Bond material
bond_material = Material.find_by(description: 'Papel bond 90 g/m²')
if bond_material.nil?
  puts "❌ Bond material not found in production"
  exit
end

puts "Material: #{bond_material.description}"
puts "ID: #{bond_material.id}"
puts "Price: $#{bond_material.price}/#{bond_material.unit&.abbreviation || 'unit'}"
puts "Dimensions: #{bond_material.ancho}cm × #{bond_material.largo}cm"
puts "Weight: #{bond_material.weight || 'Not defined'}"
puts "Unit: #{bond_material.unit&.name} (#{bond_material.unit&.abbreviation})"

# Check if there are any users with this material
users_with_material = User.joins(:materials).where(materials: { id: bond_material.id })
puts "\nUsers with this material: #{users_with_material.count}"

if users_with_material.count > 0
  user = users_with_material.first
  puts "First user: #{user.email}"
  
  # Check user's association with this material
  user_material = user.user_materials.find_by(material_id: bond_material.id)
  if user_material
    puts "User material association found:"
    puts "  Price: $#{user_material.price}"
    puts "  Created at: #{user_material.created_at}"
  end
end

# Check recent products to see how materials are being calculated
puts "\n📦 Recent products with materials:"
recent_products = Product.includes(:user).where.not(data: nil).order(created_at: :desc).limit(5)

recent_products.each do |product|
  puts "\nProduct ID: #{product.id}"
  puts "User: #{product.user.email}"
  puts "Created: #{product.created_at}"
  
  if product.data && product.data['materials']
    materials = product.data['materials']
    puts "Materials count: #{materials.length}"
    
    materials.each_with_index do |material, index|
      puts "  Material #{index + 1}:"
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
end 