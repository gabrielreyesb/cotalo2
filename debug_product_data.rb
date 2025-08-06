#!/usr/bin/env ruby

# Script para verificar los datos del producto
require_relative 'config/environment'

puts "=== VERIFICACIÓN DE DATOS DEL PRODUCTO ==="

# Buscar el producto "Producto nuevo"
product = Product.where("description LIKE ?", "%Producto nuevo%").order(created_at: :desc).first

if product
  puts "Producto encontrado: #{product.description}"
  puts "ID: #{product.id}"
  
  # Verificar general_info
  puts "\n=== GENERAL INFO ==="
  general_info = product.general_info
  puts "General info completo: #{general_info.inspect}"
  
  # Verificar inner_measurements específicamente
  puts "\n=== INNER MEASUREMENTS ==="
  inner_measurements = general_info["inner_measurements"]
  puts "Inner measurements: #{inner_measurements.inspect}"
  
  if inner_measurements.is_a?(Hash)
    puts "  - Width: #{inner_measurements['width']}"
    puts "  - Length: #{inner_measurements['length']}"
    puts "  - Height: #{inner_measurements['height']}"
  elsif inner_measurements.is_a?(String)
    puts "  - Inner measurements (string): #{inner_measurements}"
  else
    puts "  - Inner measurements (tipo): #{inner_measurements.class}"
  end
  
  # Verificar si hay datos en otras ubicaciones
  puts "\n=== BUSCANDO DIMENSIONES EN OTRAS UBICACIONES ==="
  
  # Buscar en data directamente
  if product.data["inner_measurements"]
    puts "Encontrado en product.data['inner_measurements']: #{product.data['inner_measurements'].inspect}"
  end
  
  # Buscar en general_info con diferentes claves
  ["width", "length", "height", "ancho", "largo", "alto"].each do |key|
    if general_info[key]
      puts "Encontrado general_info['#{key}']: #{general_info[key]}"
    end
  end
  
  # Verificar si hay datos en el nivel raíz de data
  ["width", "length", "height", "ancho", "largo", "alto"].each do |key|
    if product.data[key]
      puts "Encontrado product.data['#{key}']: #{product.data[key]}"
    end
  end
  
  # Mostrar estructura completa de data para debugging
  puts "\n=== ESTRUCTURA COMPLETA DE DATA ==="
  puts "Keys en product.data: #{product.data.keys}"
  
  # Verificar quantity
  puts "\n=== QUANTITY ==="
  puts "Quantity en general_info: #{general_info['quantity']}"
  puts "Quantity en data: #{product.data['quantity']}"
  
else
  puts "No se encontró el producto"
end 