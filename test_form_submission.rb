#!/usr/bin/env ruby

# Script para simular el envío del formulario de PDF configs
require_relative 'config/environment'

puts "=== SIMULACIÓN DE ENVÍO DE FORMULARIO ==="

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
    
    # Simular parámetros como los que vienen del formulario (con logo_url vacío)
    test_params = {
      footer_text: "Texto de prueba formulario #{Time.current.to_i}",
      logo_url: "", # URL vacía como en el formulario
      signature_name: "Test User Form"
    }
    
    puts "\n=== PARÁMETROS DEL FORMULARIO ==="
    puts "Parámetros originales: #{test_params.inspect}"
    
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
      
      # Verificar si el logo se mantuvo
      if pdf_config.logo_url == "https://res.cloudinary.com/cotalo/image/upload/v1754353935/pdf_logos/68/logo_real_1754353934.png"
        puts "✅ Logo URL se mantuvo correctamente"
      else
        puts "❌ Logo URL cambió: #{pdf_config.logo_url}"
      end
    else
      puts "❌ Error en actualización: #{pdf_config.errors.full_messages}"
    end
  else
    puts "❌ No hay PDF config para este usuario"
  end
else
  puts "❌ Usuario no encontrado"
end 