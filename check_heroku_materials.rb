#!/usr/bin/env ruby

# Script to check materials in Heroku production
puts "🔍 Checking materials in Heroku production"
puts "=" * 50

# Find the Bond material
bond_material = Material.find_by(description: 'Papel bond 90 g/m²')
if bond_material.nil?
  puts "❌ Bond material not found in production"
  exit
end

puts "✅ Bond material found:"
puts "ID: #{bond_material.id}"
puts "Description: #{bond_material.description}"
puts "Unit: #{bond_material.unit&.name}"
puts "Unit abbreviation: #{bond_material.unit&.abbreviation}"
puts "Price: $#{bond_material.price}"
puts "Weight: #{bond_material.weight || 'Not defined'}"
puts "Dimensions: #{bond_material.ancho}cm × #{bond_material.largo}cm"

# Check if it's weight-based or area-based
puts "\n📊 Material type detection:"
puts "Weight-based pricing: #{bond_material.weight_based_pricing?}"
puts "Area-based pricing: #{bond_material.area_based_pricing?}"

# Check all materials for this user
user = User.first
puts "\n👤 User: #{user.email}"
puts "User materials count: #{user.materials.count}"

# Show all materials for this user
puts "\n📦 All user materials:"
user.materials.each_with_index do |material, index|
  puts "\n#{index + 1}. #{material.description}"
  puts "   Unit: #{material.unit&.name} (#{material.unit&.abbreviation})"
  puts "   Price: $#{material.price}"
  puts "   Weight-based: #{material.weight_based_pricing?}"
  puts "   Area-based: #{material.area_based_pricing?}"
end

puts "\n✅ Check completed!" 