#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== DEBUG PROCESOS GLOBALES ==="

# Buscar productos que tengan procesos globales
products = Product.all

puts "Revisando #{products.size} productos..."

products_with_global_processes = []

products.each do |product|
  # Verificar diferentes posibles ubicaciones de procesos globales
  global_processes = []
  
  # 1. Verificar product.data['global_processes']
  if product.data && product.data['global_processes']
    global_processes = product.data['global_processes']
    puts "\n=== PRODUCTO #{product.id}: #{product.description} ==="
    puts "Encontrados #{global_processes.size} procesos globales en product.data['global_processes']"
    global_processes.each_with_index do |process, index|
      puts "  Proceso #{index + 1}: #{process['description'] || process['name']} - $#{process['price'] || process['unitPrice']}"
    end
    products_with_global_processes << product
  end
  
  # 2. Verificar product.data['processes'] que no tengan materialId
  if product.data && product.data['processes']
    global_from_processes = product.data['processes'].select { |p| !p['materialId'] }
    if global_from_processes.any?
      puts "\n=== PRODUCTO #{product.id}: #{product.description} ==="
      puts "Encontrados #{global_from_processes.size} procesos globales en product.data['processes'] (sin materialId)"
      global_from_processes.each_with_index do |process, index|
        puts "  Proceso #{index + 1}: #{process['description'] || process['name']} - $#{process['price'] || process['unitPrice']}"
      end
      products_with_global_processes << product unless products_with_global_processes.include?(product)
    end
  end
  
  # 3. Verificar product.processes que no tengan materialId
  if product.processes
    global_from_processes_method = product.processes.select { |p| !p['materialId'] }
    if global_from_processes_method.any?
      puts "\n=== PRODUCTO #{product.id}: #{product.description} ==="
      puts "Encontrados #{global_from_processes_method.size} procesos globales en product.processes (sin materialId)"
      global_from_processes_method.each_with_index do |process, index|
        puts "  Proceso #{index + 1}: #{process['description'] || process['name']} - $#{process['price'] || process['unitPrice']}"
      end
      products_with_global_processes << product unless products_with_global_processes.include?(product)
    end
  end
end

if products_with_global_processes.empty?
  puts "\n❌ NO SE ENCONTRARON PRODUCTOS CON PROCESOS GLOBALES"
  puts "\n=== VERIFICANDO ESTRUCTURA DE DATOS ==="
  
  # Revisar la estructura de un producto reciente
  recent_product = Product.last
  if recent_product
    puts "Producto reciente: #{recent_product.description} (ID: #{recent_product.id})"
    puts "Claves en product.data: #{recent_product.data.keys if recent_product.data}"
    
    if recent_product.data
      puts "\nEstructura completa de product.data:"
      puts recent_product.data.inspect
    end
  end
else
  puts "\n✅ SE ENCONTRARON #{products_with_global_processes.size} PRODUCTOS CON PROCESOS GLOBALES"
end 