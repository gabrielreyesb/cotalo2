#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== DEBUG CAMPOS DE COSTOS ==="

# Find the product
product = Product.find(315)

if product
  puts "Producto: #{product.description}"
  
  puts "\n=== PROCESOS GLOBALES (CAMPOS DISPONIBLES) ==="
  global_processes = product.processes&.select { |process| !process["materialId"] } || []
  puts "Encontrados #{global_processes.size} procesos globales:"
  
  global_processes.each_with_index do |process, index|
    puts "\n--- Proceso Global #{index + 1} ---"
    puts "Descripción: #{process['description']}"
    puts "Todos los campos disponibles: #{process.keys}"
    puts "Price: #{process['price']}"
    puts "Cost: #{process['cost']}"
    puts "UnitPrice: #{process['unitPrice']}"
    puts "Subtotal: #{process['subtotal']}"
    puts "Subtotal_price: #{process['subtotal_price']}"
  end
  
  puts "\n=== COSTOS INDIRECTOS (CAMPOS DISPONIBLES) ==="
  indirect_costs = product.extras || []
  puts "Encontrados #{indirect_costs.size} costos indirectos:"
  
  indirect_costs.each_with_index do |cost, index|
    puts "\n--- Costo Indirecto #{index + 1} ---"
    puts "Descripción: #{cost['name'] || cost['description']}"
    puts "Todos los campos disponibles: #{cost.keys}"
    puts "Cost: #{cost['cost']}"
    puts "Price: #{cost['price']}"
    puts "Percentage: #{cost['percentage']}"
    puts "Value: #{cost['value']}"
    puts "Amount: #{cost['amount']}"
  end
  
else
  puts "No se encontró el producto con ID 315"
end 