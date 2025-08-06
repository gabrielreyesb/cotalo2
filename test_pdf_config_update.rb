#!/usr/bin/env ruby

# Script para probar la actualización del PDF config
require_relative 'config/environment'

puts "=== PRUEBA DE ACTUALIZACIÓN DE PDF CONFIG ==="

# Buscar el usuario
user = User.find_by(email: 'gabrielreyesb+80@gmail.com')

if user
  puts "Usuario encontrado: #{user.email} (ID: #{user.id})"
  
  pdf_config = user.pdf_config
  if pdf_config
    puts "\n=== ESTADO ACTUAL ==="
    puts "Logo URL actual: #{pdf_config.logo_url || 'N/A'}"
    puts "Footer text actual: #{pdf_config.footer_text || 'N/A'}"
    puts "Signature name actual: #{pdf_config.signature_name || 'N/A'}"
    
    # Simular parámetros como los que vienen del formulario
    test_logo_url = "https://res.cloudinary.com/cotalo/image/upload/v1754353935/pdf_logos/68/logo_real_1754353934.png"
    test_params = {
      footer_text: "Texto de prueba actualizado #{Time.current.to_i}",
      logo_url: test_logo_url,
      signature_name: "Test User Updated"
    }
    
    puts "\n=== PARÁMETROS DE PRUEBA ==="
    puts "Parámetros: #{test_params.inspect}"
    
    # Aplicar la lógica del controlador
    if test_params[:logo_url].blank? && pdf_config.logo_url.present?
      puts "⚠️  Eliminando logo_url vacío para proteger la URL actual"
      test_params.delete(:logo_url)
    else
      puts "✅ logo_url no está vacío o no hay URL actual que proteger"
    end
    
    puts "Parámetros después de protección: #{test_params.inspect}"
    
    # Intentar actualizar
    puts "\n=== ACTUALIZANDO ==="
    result = pdf_config.update(test_params)
    
    if result
      puts "✅ Actualización exitosa"
      pdf_config.reload
      puts "Logo URL después: #{pdf_config.logo_url}"
      puts "Footer text después: #{pdf_config.footer_text}"
      puts "Signature name después: #{pdf_config.signature_name}"
    else
      puts "❌ Error en actualización: #{pdf_config.errors.full_messages}"
    end
  else
    puts "❌ No hay PDF config para este usuario"
  end
else
  puts "❌ Usuario no encontrado"
end 