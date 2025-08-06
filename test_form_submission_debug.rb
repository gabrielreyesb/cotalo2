#!/usr/bin/env ruby

# Script para debuggear exactamente qué está pasando cuando se envía el formulario
require_relative 'config/environment'

puts "=== DEBUG FORM SUBMISSION ==="

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
    
    # Simular parámetros exactos como los que vienen del formulario (con logo_url vacío)
    test_params = {
      "pdf_config" => {
        "footer_text" => "Texto de prueba debug #{Time.current.to_i}",
        "logo_url" => "", # URL vacía como en el formulario
        "signature_name" => "Test User Debug"
      }
    }
    
    puts "\n=== PARÁMETROS DEL FORMULARIO ==="
    puts "Parámetros: #{test_params.inspect}"
    
    # Simular el proceso del controlador
    puts "\n=== SIMULANDO CONTROLADOR ==="
    
    # Extraer los parámetros como lo hace el controlador
    pdf_config_params = test_params["pdf_config"]
    puts "pdf_config_params: #{pdf_config_params.inspect}"
    
    # Aplicar la lógica de protección
    update_params = pdf_config_params.dup
    if update_params["logo_url"].blank? && pdf_config.logo_url.present?
      puts "⚠️  logo_url está vacío, eliminando del hash para proteger la URL actual"
      update_params.delete("logo_url")
    else
      puts "✅ logo_url no está vacío o no hay URL actual que proteger"
    end
    
    puts "Parámetros después de protección: #{update_params.inspect}"
    
    # Intentar actualizar
    puts "\n=== ACTUALIZANDO ==="
    result = pdf_config.update(update_params)
    
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