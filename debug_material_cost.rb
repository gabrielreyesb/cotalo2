#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== DEBUG MATERIAL COST STRUCTURE ==="

# Find the product
product = Product.where("description LIKE ?", "%Producto nuevo%").order(created_at: :desc).first

if product
  puts "Producto encontrado: #{product.description}"
  puts "ID: #{product.id}"
  puts "\n=== ESTRUCTURA DE MATERIALES ==="
  
  if product.materials.present?
    product.materials.each_with_index do |material, index|
      puts "\n--- Material #{index + 1} ---"
      puts "Nombre: #{material['name'] || material['description']}"
      puts "Cost: #{material['cost']}"
      puts "Subtotal_price: #{material['subtotal_price']}"
      puts "Price: #{material['price']}"
      puts "Total_cost: #{material['total_cost']}"
      puts "Material_cost: #{material['material_cost']}"
      
      # Show all keys in the material hash
      puts "Todas las claves disponibles: #{material.keys}"
      
      # Show processes and their costs
      if material['processes'].present?
        puts "\nProcesos:"
        material['processes'].each_with_index do |process, p_index|
          puts "  Proceso #{p_index + 1}:"
          puts "    Name: #{process['name']}"
          puts "    Price: #{process['price']}"
          puts "    Subtotal_price: #{process['subtotal_price']}"
          puts "    Cost: #{process['cost']}"
          puts "    UnitPrice: #{process['unitPrice']}"
        end
      end
    end
  else
    puts "No hay materiales en este producto"
  end
  
  puts "\n=== ESTRUCTURA COMPLETA DEL PRODUCTO ==="
  puts "General info: #{product.general_info}"
  puts "Materials: #{product.materials}"
  puts "Pricing: #{product.pricing}"
  
else
  puts "No se encontró el producto 'Producto nuevo'"
end 