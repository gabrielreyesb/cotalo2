#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== DEBUG FORM SUBMISSION ==="

# Buscar el usuario
user = User.find_by(email: "gabrielreyesb+80@gmail.com")
puts "Usuario: #{user.email}"

# Verificar configuración actual
pdf_config = user.pdf_config
puts "Logo URL actual en BD: #{pdf_config.logo_url}"

# Simular los parámetros que se envían en el formulario
puts "\n=== SIMULANDO PARÁMETROS DEL FORMULARIO ==="

# Parámetros típicos que se envían
form_params = {
  pdf_config: {
    footer_text: "Texto de prueba",
    logo_url: "", # Esto es lo que probablemente se está enviando
    signature_name: "Test User",
    signature_email: "test@example.com",
    signature_phone: "123456789",
    signature_whatsapp: "123456789",
    sales_condition_1: "",
    sales_condition_2: "",
    sales_condition_3: "",
    sales_condition_4: ""
  }
}

puts "Parámetros que se envían:"
puts form_params.inspect

# Simular el método update del controlador
puts "\n=== SIMULANDO MÉTODO UPDATE ==="

# Proteger la URL del logo - no permitir que se sobrescriba con valores vacíos
update_params = form_params[:pdf_config]
puts "Parámetros originales: #{update_params.inspect}"

if update_params[:logo_url].blank? && pdf_config.logo_url.present?
  puts "⚠️  logo_url está vacío, eliminando del hash para proteger la URL actual"
  update_params.delete(:logo_url)
  puts "Parámetros después de proteger logo_url: #{update_params.inspect}"
else
  puts "✅ logo_url no está vacío o no hay URL actual que proteger"
end

# Simular la actualización
puts "\n=== SIMULANDO ACTUALIZACIÓN ==="
puts "URL antes de actualizar: #{pdf_config.logo_url}"

# No actualizar realmente, solo simular
puts "Si se actualizara, los parámetros serían: #{update_params.inspect}"

# Verificar si hay algún problema con el modelo
puts "\n=== VERIFICANDO MODELO ==="
puts "PDF Config ID: #{pdf_config.id}"
puts "User ID: #{pdf_config.user_id}"
puts "Logo URL presente: #{pdf_config.logo_url.present?}"
puts "Logo URL blank: #{pdf_config.logo_url.blank?}"

# Verificar si hay callbacks o validaciones que puedan estar interfiriendo
puts "\n=== VERIFICANDO CALLBACKS ==="
puts "Callbacks en PdfConfig:"
PdfConfig._save_callbacks.each do |callback|
  puts "  - #{callback.kind}: #{callback.filter}"
end

puts "\nValidaciones en PdfConfig:"
PdfConfig.validators.each do |validator|
  puts "  - #{validator.class}: #{validator.attributes}"
end 