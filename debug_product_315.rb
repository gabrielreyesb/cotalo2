#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== DEBUG PRODUCTO 315 ==="

# Find the product
product = Product.find(315)

if product
  puts "Producto encontrado: #{product.description}"
  puts "ID: #{product.id}"
  
  puts "\n=== ESTRUCTURA COMPLETA DEL PRODUCTO ==="
  puts "General info: #{product.general_info}"
  puts "Materials: #{product.materials&.size || 0} materiales"
  puts "Processes: #{product.processes&.size || 0} procesos"
  puts "Extras: #{product.extras&.size || 0} extras"
  puts "Pricing: #{product.pricing}"
  
  puts "\n=== PROCESOS GLOBALES ==="
  puts "product.processes: #{product.processes}"
  puts "product.data['global_processes']: #{product.data&.dig('global_processes')}"
  puts "product.data['processes']: #{product.data&.dig('processes')}"
  
  puts "\n=== COSTOS INDIRECTOS ==="
  puts "product.data['indirect_costs']: #{product.data&.dig('indirect_costs')}"
  puts "product.data['costs']: #{product.data&.dig('costs')}"
  
  puts "\n=== TODAS LAS CLAVES EN product.data ==="
  if product.data
    puts product.data.keys
  else
    puts "product.data es nil"
  end
  
  puts "\n=== ESTRUCTURA DE MATERIALES ==="
  if product.materials.present?
    product.materials.each_with_index do |material, index|
      puts "\n--- Material #{index + 1} ---"
      puts "Nombre: #{material['name'] || material['description']}"
      puts "Procesos: #{material['processes']&.size || 0}"
      if material['processes'].present?
        material['processes'].each_with_index do |process, p_index|
          puts "  Proceso #{p_index + 1}: #{process['name'] || process['description']} - $#{process['price']}"
        end
      end
    end
  end
  
  puts "\n=== PROCESOS GLOBALES DETALLADOS ==="
  global_processes = product.data&.dig('global_processes') || []
  puts "Encontrados #{global_processes.size} procesos globales:"
  global_processes.each_with_index do |process, index|
    puts "  Proceso #{index + 1}: #{process['name'] || process['description']} - $#{process['cost']}"
  end
  
  puts "\n=== COSTOS INDIRECTOS DETALLADOS ==="
  indirect_costs = product.data&.dig('indirect_costs') || []
  puts "Encontrados #{indirect_costs.size} costos indirectos:"
  indirect_costs.each_with_index do |cost, index|
    puts "  Costo #{index + 1}: #{cost['name'] || cost['description']} - #{cost['percentage']}%"
  end
  
else
  puts "No se encontró el producto con ID 315"
end 