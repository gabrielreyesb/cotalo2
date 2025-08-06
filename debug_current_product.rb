#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== DEBUG PRODUCTO ACTUAL ==="

# Obtener el último producto creado o uno específico
product = Product.last

if product
  puts "Producto encontrado: #{product.description}"
  puts "ID: #{product.id}"
  puts "Usuario: #{product.user.email}"
  
  puts "\n=== ESTRUCTURA COMPLETA DEL PRODUCTO ==="
  puts "General info: #{product.general_info}"
  puts "Materials: #{product.materials&.size || 0} materiales"
  puts "Processes: #{product.processes&.size || 0} procesos"
  puts "Extras: #{product.extras&.size || 0} extras"
  puts "Pricing: #{product.pricing}"
  
  puts "\n=== PROCESOS GLOBALES ==="
  puts "product.data['global_processes']: #{product.data&.dig('global_processes')}"
  puts "product.data['processes']: #{product.data&.dig('processes')}"
  puts "product.processes: #{product.processes}"
  
  puts "\n=== TODAS LAS CLAVES EN product.data ==="
  if product.data
    puts "Claves disponibles: #{product.data.keys}"
    
    puts "\n=== ESTRUCTURA COMPLETA DE product.data ==="
    puts product.data.inspect
  else
    puts "product.data es nil"
  end
  
  puts "\n=== PROCESOS GLOBALES DETALLADOS ==="
  global_processes = product.data&.dig('global_processes') || []
  puts "Encontrados #{global_processes.size} procesos globales:"
  
  if global_processes.any?
    global_processes.each_with_index do |process, index|
      puts "\n--- Proceso Global #{index + 1} ---"
      puts "Todos los campos: #{process.keys}"
      puts "Description: #{process['description']}"
      puts "Name: #{process['name']}"
      puts "Price: #{process['price']}"
      puts "UnitPrice: #{process['unitPrice']}"
      puts "Veces: #{process['veces']}"
      puts "Process ID: #{process['process_id']}"
      puts "ID: #{process['id']}"
    end
  else
    puts "No se encontraron procesos globales en product.data['global_processes']"
    
    # Verificar si hay procesos en el array general de procesos
    puts "\n=== VERIFICANDO PROCESOS GENERALES ==="
    all_processes = product.data&.dig('processes') || []
    puts "Procesos generales encontrados: #{all_processes.size}"
    
    if all_processes.any?
      all_processes.each_with_index do |process, index|
        puts "\n--- Proceso #{index + 1} ---"
        puts "Todos los campos: #{process.keys}"
        puts "Description: #{process['description']}"
        puts "Name: #{process['name']}"
        puts "Material ID: #{process['materialId']}"
        puts "Es global: #{process['materialId'].nil? ? 'SÍ' : 'NO'}"
      end
    end
  end
  
else
  puts "No se encontró ningún producto"
end 