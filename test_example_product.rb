#!/usr/bin/env ruby

# Test script to verify example product calculation
require_relative 'config/environment'

puts "Testing example product calculation..."

# Find a user with example data
user = User.first
if user.nil?
  puts "No users found. Please create a user first."
  exit
end

puts "Testing with user: #{user.email}"

# Find the example product
example_product = user.example_product
if example_product.nil?
  puts "No example product found for user."
  exit
end

puts "Found example product: #{example_product.description}"

# Check the current pricing data
puts "\nBefore calculate_totals:"
puts "Materials cost: #{example_product.data['pricing']['materials_cost']}"
puts "Processes cost: #{example_product.data['pricing']['processes_cost']}"
puts "Extras cost: #{example_product.data['pricing']['extras_cost']}"
puts "Total price: #{example_product.data['pricing']['total_price']}"
puts "Final price per piece: #{example_product.data['pricing']['final_price_per_piece']}"

# Calculate totals
example_product.calculate_totals

puts "\nAfter calculate_totals:"
puts "Materials cost: #{example_product.data['pricing']['materials_cost']}"
puts "Processes cost: #{example_product.data['pricing']['processes_cost']}"
puts "Extras cost: #{example_product.data['pricing']['extras_cost']}"
puts "Subtotal: #{example_product.data['pricing']['subtotal']}"
puts "Waste value: #{example_product.data['pricing']['waste_value']}"
puts "Margin value: #{example_product.data['pricing']['margin_value']}"
puts "Total price: #{example_product.data['pricing']['total_price']}"
puts "Final price per piece: #{example_product.data['pricing']['final_price_per_piece']}"

# Check if the product has a non-zero price
if example_product.data['pricing']['total_price'].to_f > 0
  puts "\n✅ SUCCESS: Example product has a non-zero price!"
else
  puts "\n❌ FAILURE: Example product still has zero price."
end

# Test the quote calculation
example_quote = user.quotes.first
if example_quote
  puts "\nTesting quote calculation..."
  puts "Quote before calculate_totals:"
  puts "Subtotal: #{example_quote.data['totals']['subtotal']}"
  puts "Total: #{example_quote.data['totals']['total']}"
  
  example_quote.calculate_totals
  
  puts "Quote after calculate_totals:"
  puts "Subtotal: #{example_quote.data['totals']['subtotal']}"
  puts "Total: #{example_quote.data['totals']['total']}"
  
  if example_quote.data['totals']['total'].to_f > 0
    puts "✅ SUCCESS: Example quote has a non-zero total!"
  else
    puts "❌ FAILURE: Example quote still has zero total."
  end
else
  puts "No example quote found."
end 