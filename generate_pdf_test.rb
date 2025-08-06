#!/usr/bin/env ruby

# Script para generar un PDF de cotización de prueba
# Uso: rails runner generate_pdf_test.rb

puts "=== Generando PDF de prueba ==="

# Buscar un usuario con cotizaciones
user = User.joins(:quotes).first
if user.nil?
  puts "❌ No se encontró ningún usuario con cotizaciones"
  exit 1
end

puts "👤 Usuario: #{user.email}"

# Buscar una cotización
quote = user.quotes.first
if quote.nil?
  puts "❌ No se encontró ninguna cotización"
  exit 1
end

puts "📄 Cotización: #{quote.quote_number}"

# Verificar configuración de PDF
pdf_config = user.pdf_config
if pdf_config&.logo_url.present?
  puts "✅ Logo configurado: #{pdf_config.logo_url}"
else
  puts "⚠️  No hay logo configurado"
end

# Generar PDF
puts "🔄 Generando PDF..."

begin
  generator = QuotePdfGenerator.new(quote)
  pdf_content = generator.generate
  
  # Guardar PDF en archivo temporal
  filename = "test_quote_#{quote.quote_number}.pdf"
  File.binwrite(filename, pdf_content)
  
  puts "✅ PDF generado exitosamente: #{filename}"
  puts "📁 Ubicación: #{File.expand_path(filename)}"
  puts "📊 Tamaño: #{pdf_content.bytesize} bytes"
  
rescue => e
  puts "❌ Error generando PDF: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end 