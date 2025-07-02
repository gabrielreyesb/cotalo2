#!/usr/bin/env ruby

# Simple script to examine product data structure
require_relative 'config/environment'

puts "Examining product data structure..."
puts "=" * 50

# Get the first product with processes
product = Product.joins(:user).where("data->>'processes' IS NOT NULL AND json_array_length(data->'processes') > 0").first

if product
  puts "Found product: #{product.description}"
  puts "User: #{product.user.email}"
  puts "Data structure:"
  puts JSON.pretty_generate(product.data)
  
  if product.data["processes"]
    puts "\nProcesses:"
    product.data["processes"].each_with_index do |process, index|
      puts "  Process #{index + 1}:"
      puts "    #{JSON.pretty_generate(process)}"
    end
  end
else
  puts "No products with processes found."
  
  # Show all products
  puts "\nAll products:"
  Product.limit(5).each do |p|
    puts "  #{p.description} - Data keys: #{p.data.keys.join(', ')}"
  end
end 