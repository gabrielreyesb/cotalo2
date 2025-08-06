#!/usr/bin/env ruby

# Script para generar el PDF moderno y probar el logo en la esquina superior derecha
require_relative 'config/environment'

puts "=== GENERADOR DE PDF MODERNO ==="

# Buscar un usuario con PDF config
user = User.includes(:pdf_config).first
if user.nil?
  puts "❌ No se encontró ningún usuario"
  exit 1
end

puts "👤 Usuario: #{user.email}"
puts "📋 PDF Config ID: #{user.pdf_config&.id}"
puts "🖼️  Logo URL: #{user.pdf_config&.logo_url}"

# Buscar una cotización existente o crear una nueva
quote = user.quotes.includes(:quote_products => [:product]).first

if quote.nil?
  puts "❌ No se encontró ninguna cotización"
  exit 1
end

puts "📄 Cotización: #{quote.quote_number}"
puts "📦 Productos: #{quote.quote_products.count}"

# Generar PDF moderno
puts "\n=== GENERANDO PDF MODERNO ==="
begin
  pdf_generator = QuotePdfGeneratorModern.new(quote)
  pdf_content = pdf_generator.generate
  
  # Guardar el PDF
  filename = "test_modern_pdf_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf"
  File.binwrite(filename, pdf_content)
  
  puts "✅ PDF moderno generado exitosamente: #{filename}"
  puts "📏 Tamaño del archivo: #{pdf_content.bytesize} bytes"
  
  # Verificar que el archivo se creó correctamente
  if File.exist?(filename) && File.size(filename) > 0
    puts "✅ Archivo guardado correctamente"
    puts "📁 Ruta completa: #{File.expand_path(filename)}"
  else
    puts "❌ Error al guardar el archivo"
  end
  
rescue => e
  puts "❌ Error generando PDF moderno: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
end

puts "\n=== COMPLETADO ==="
puts "Abre el archivo #{filename} para verificar que el logo aparece en la esquina superior derecha" 