#!/usr/bin/env ruby

# Script temporal para probar el footer más delgado
require_relative 'config/environment'

puts "=== PRUEBA DEL FOOTER MÁS DELGADO ==="

# Buscar el producto específico con ID 316
product = Product.find(316)
if product
  puts "Producto encontrado: #{product.description}"
  
  # Calcular pricing del producto si no existe
  if product.pricing.blank?
    puts "Calculando pricing del producto..."
    product.calculate_pricing!
    product.reload
  end
  
  puts "Pricing del producto: #{product.pricing}"
  
  # Crear una cotización de prueba
  customer = Customer.find_or_create_by(email: "test_footer@example.com") do |c|
    c.name = "Cliente Footer Test"
    c.company = "Empresa Footer Test"
    c.phone = "1234567890"
  end
  
  quote = Quote.create!(
    user: product.user,
    customer_name: customer.name,
    organization: customer.company,
    email: customer.email,
    telephone: customer.phone,
    project_name: "Prueba Footer Delgado",
    quote_number: "COT-#{Time.current.strftime('%Y%m%d')}-#{rand(1000..9999)}",
    data: Quote.default_data
  )
  
  QuoteProduct.create!(
    quote: quote,
    product: product,
    quantity: 1
  )
  
  puts "Cotización creada: #{quote.quote_number}"
  
  # Generar PDF
  puts "\n=== GENERANDO PDF CON FOOTER DELGADO ==="
  begin
    pdf_generator = QuotePdfGeneratorDetailed.new(quote)
    pdf_content = pdf_generator.generate
    
    filename = "footer_test.pdf"
    File.binwrite(filename, pdf_content)
    
    puts "✅ PDF generado exitosamente: #{filename}"
    puts "Tamaño del archivo: #{pdf_content.bytesize} bytes"
    puts "\n=== INSTRUCCIONES ==="
    puts "1. Abre el archivo: #{filename}"
    puts "2. Verifica que el footer sea más delgado"
    puts "3. Compara con el footer anterior"
  rescue => e
    puts "❌ Error generando PDF: #{e.message}"
    puts e.backtrace.join("\n")
  end
else
  puts "❌ No se encontró el producto con ID 316"
end 