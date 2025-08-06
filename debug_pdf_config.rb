#!/usr/bin/env ruby

# Script para debuggear el problema con el logo en PDF configs
require_relative 'config/environment'

puts "=== DEBUG PDF CONFIG LOGO ==="

# Buscar usuarios con PDF configs
users_with_pdf_configs = User.joins(:pdf_config).limit(5)

puts "\n=== USUARIOS CON PDF CONFIGS ==="
users_with_pdf_configs.each do |user|
  pdf_config = user.pdf_config
  puts "Usuario: #{user.email} (ID: #{user.id})"
  puts "  - Logo URL: #{pdf_config.logo_url || 'N/A'}"
  puts "  - Footer text: #{pdf_config.footer_text || 'N/A'}"
  puts "  - Signature name: #{pdf_config.signature_name || 'N/A'}"
  puts "  - Creado: #{pdf_config.created_at}"
  puts "  - Actualizado: #{pdf_config.updated_at}"
  puts ""
end

# Buscar específicamente el usuario que está teniendo problemas
puts "\n=== BUSCANDO USUARIO ESPECÍFICO ==="
user = User.find_by(email: 'gabrielreyesb+80@gmail.com')

if user
  puts "Usuario encontrado: #{user.email} (ID: #{user.id})"
  
  pdf_config = user.pdf_config
  if pdf_config
    puts "PDF Config encontrado:"
    puts "  - Logo URL: #{pdf_config.logo_url || 'N/A'}"
    puts "  - Footer text: #{pdf_config.footer_text || 'N/A'}"
    puts "  - Signature name: #{pdf_config.signature_name || 'N/A'}"
    puts "  - Creado: #{pdf_config.created_at}"
    puts "  - Actualizado: #{pdf_config.updated_at}"
    
    # Verificar si la URL del logo es válida
    if pdf_config.logo_url.present?
      puts "\n=== VERIFICANDO URL DEL LOGO ==="
      begin
        require 'net/http'
        require 'uri'
        
        uri = URI(pdf_config.logo_url)
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          puts "✅ URL del logo es válida y accesible"
          puts "  - Tamaño: #{response.body.length} bytes"
          puts "  - Content-Type: #{response['content-type']}"
        else
          puts "❌ URL del logo no es accesible (código: #{response.code})"
        end
      rescue => e
        puts "❌ Error verificando URL del logo: #{e.message}"
      end
    else
      puts "⚠️  No hay URL de logo configurada"
    end
  else
    puts "❌ No hay PDF config para este usuario"
  end
else
  puts "❌ Usuario no encontrado"
end

# Simular el problema
puts "\n=== SIMULANDO EL PROBLEMA ==="
if user && user.pdf_config
  pdf_config = user.pdf_config
  
  # Simular parámetros como los que vienen del formulario
  test_params = {
    footer_text: "Texto de prueba #{Time.current.to_i}",
    logo_url: "", # URL vacía como en el formulario
    signature_name: "Test User"
  }
  
  puts "Parámetros de prueba: #{test_params.inspect}"
  puts "Logo URL actual: #{pdf_config.logo_url}"
  
  # Aplicar la lógica del controlador
  if test_params[:logo_url].blank? && pdf_config.logo_url.present?
    puts "⚠️  Eliminando logo_url vacío para proteger la URL actual"
    test_params.delete(:logo_url)
  end
  
  puts "Parámetros después de protección: #{test_params.inspect}"
  
  # Verificar qué pasaría si se actualiza
  puts "\n=== VERIFICANDO QUÉ PASARÍA ==="
  if test_params.key?(:logo_url)
    puts "❌ PROBLEMA: logo_url está en los parámetros y se sobrescribiría"
  else
    puts "✅ OK: logo_url no está en los parámetros, se preservaría"
  end
end 