#!/usr/bin/env ruby

# Script para obtener información del producto "Producto nuevo"
require_relative 'config/environment'

puts "Buscando producto 'Producto nuevo'..."
product = Product.where("description LIKE ?", "%Producto nuevo%").order(created_at: :desc).first

if product
  puts "\n=== INFORMACIÓN DEL PRODUCTO ==="
  puts "ID: #{product.id}"
  puts "Descripción: #{product.description}"
  puts "Creado: #{product.created_at}"
  puts "Usuario: #{product.user.email}"
  
  puts "\n=== DATOS DEL PRODUCTO ==="
  puts "Data: #{product.data.inspect}"
  
  puts "\n=== MATERIALES ==="
  if product.data["materials"]
    product.data["materials"].each_with_index do |material, index|
      puts "Material #{index + 1}:"
      puts "  - Nombre: #{material['name']}"
      puts "  - Cantidad: #{material['quantity']}"
      puts "  - Unidad: #{material['unit']}"
      puts "  - Costo: #{material['cost']}"
    end
  end
  
  puts "\n=== PROCESOS ==="
  if product.data["processes"]
    product.data["processes"].each_with_index do |process, index|
      puts "Proceso #{index + 1}:"
      puts "  - Nombre: #{process['name']}"
      puts "  - Costo: #{process['cost']}"
      puts "  - Tipo: #{process['type']}"
    end
  end
  
  puts "\n=== PROCESOS GLOBALES ==="
  if product.data["global_processes"]
    product.data["global_processes"].each_with_index do |process, index|
      puts "Proceso Global #{index + 1}:"
      puts "  - Nombre: #{process['name']}"
      puts "  - Costo: #{process['cost']}"
    end
  end
  
  puts "\n=== COSTOS INDIRECTOS ==="
  if product.data["indirect_costs"]
    product.data["indirect_costs"].each_with_index do |cost, index|
      puts "Costo Indirecto #{index + 1}:"
      puts "  - Nombre: #{cost['name']}"
      puts "  - Porcentaje: #{cost['percentage']}%"
    end
  end
  
  puts "\n=== EXTRAS ==="
  if product.data["extras"]
    product.data["extras"].each_with_index do |extra, index|
      puts "Extra #{index + 1}:"
      puts "  - Nombre: #{extra['name']}"
      puts "  - Costo: #{extra['cost']}"
    end
  end
else
  puts "No se encontró ningún producto con 'Producto nuevo' en el nombre"
  
  puts "\nÚltimos 5 productos creados:"
  Product.order(created_at: :desc).limit(5).each do |p|
    puts "- #{p.description} (ID: #{p.id}, Creado: #{p.created_at})"
  end
end 