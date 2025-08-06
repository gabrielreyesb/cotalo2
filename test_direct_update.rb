#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== PRUEBA DE ACTUALIZACIÓN DIRECTA ==="

# Buscar el usuario
user = User.find_by(email: "gabrielreyesb+80@gmail.com")
puts "Usuario: #{user.email}"

# Verificar configuración actual
pdf_config = user.pdf_config
puts "Logo URL antes: #{pdf_config.logo_url}"

# Simular una actualización directa
puts "\n=== ACTUALIZANDO SOLO FOOTER_TEXT ==="

begin
  # Actualizar solo el footer_text, sin tocar logo_url
  result = pdf_config.update(
    footer_text: "Texto de prueba #{Time.current.to_i}"
  )
  
  puts "Resultado de la actualización: #{result}"
  puts "Errores: #{pdf_config.errors.full_messages}" unless result
  
  # Recargar el objeto
  pdf_config.reload
  puts "Logo URL después: #{pdf_config.logo_url}"
  
  if pdf_config.logo_url == "https://res.cloudinary.com/cotalo/image/upload/v1754353935/pdf_logos/68/logo_real_1754353934.png"
    puts "✅ Logo URL se mantuvo correctamente"
  else
    puts "❌ Logo URL cambió: #{pdf_config.logo_url}"
  end
  
rescue => e
  puts "❌ Error en la actualización: #{e.message}"
  puts e.backtrace.join("\n")
end

# Probar con parámetros que incluyen logo_url vacío
puts "\n=== PROBANDO CON LOGO_URL VACÍO ==="

begin
  # Simular parámetros del formulario
  update_params = {
    footer_text: "Otro texto de prueba #{Time.current.to_i}",
    logo_url: "", # URL vacía como en el formulario
    signature_name: "Test User"
  }
  
  puts "Parámetros a actualizar: #{update_params.inspect}"
  
  # Aplicar nuestra lógica de protección
  if update_params[:logo_url].blank? && pdf_config.logo_url.present?
    puts "⚠️  Eliminando logo_url vacío para proteger la URL actual"
    update_params.delete(:logo_url)
  end
  
  puts "Parámetros después de protección: #{update_params.inspect}"
  
  # Actualizar
  result = pdf_config.update(update_params)
  
  puts "Resultado de la actualización: #{result}"
  puts "Errores: #{pdf_config.errors.full_messages}" unless result
  
  # Recargar el objeto
  pdf_config.reload
  puts "Logo URL después: #{pdf_config.logo_url}"
  
  if pdf_config.logo_url == "https://res.cloudinary.com/cotalo/image/upload/v1754353935/pdf_logos/68/logo_real_1754353934.png"
    puts "✅ Logo URL se mantuvo correctamente"
  else
    puts "❌ Logo URL cambió: #{pdf_config.logo_url}"
  end
  
rescue => e
  puts "❌ Error en la actualización: #{e.message}"
  puts e.backtrace.join("\n")
end 