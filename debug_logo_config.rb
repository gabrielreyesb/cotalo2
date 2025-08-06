#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== DEBUG LOGO CONFIG DETALLADO ==="

# Buscar el producto 315 para obtener el usuario
product = Product.find(315)
user = product.user

puts "Usuario del producto 315: #{user.email}"
puts "Tiene pdf_config: #{user.pdf_config.present?}"

if user.pdf_config.present?
  puts "Logo URL: #{user.pdf_config.logo_url}"
  puts "Logo URL presente: #{user.pdf_config.logo_url.present?}"
else
  puts "No tiene pdf_config configurado"
end

puts "\n=== VERIFICANDO OTROS USUARIOS ==="

# Buscar usuarios con email similar
User.where("email LIKE ?", "%gabrielreyesb%").each do |u|
  puts "\nUsuario: #{u.email}"
  puts "  Tiene pdf_config: #{u.pdf_config.present?}"
  if u.pdf_config.present?
    puts "  Logo URL: #{u.pdf_config.logo_url}"
  end
end

puts "\n=== VERIFICANDO TODOS LOS PDF_CONFIGS ==="
PdfConfig.all.each do |config|
  puts "\nPDF Config ID: #{config.id}"
  puts "  Usuario: #{config.user.email}"
  puts "  Logo URL: #{config.logo_url}"
end

puts "\n=== CREANDO PDF CONFIG PARA EL USUARIO CORRECTO ==="
target_user = User.find_by(email: "gabrielreyesb@gmail.com")

if target_user
  puts "Usuario encontrado: #{target_user.email}"
  
  if target_user.pdf_config.present?
    puts "Ya tiene pdf_config configurado"
    puts "Logo URL actual: #{target_user.pdf_config.logo_url}"
  else
    # Crear un pdf_config para el usuario correcto
    pdf_config = PdfConfig.create!(
      user: target_user,
      logo_url: "https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg",
      signature_name: "Ing. Carlos Mendoza",
      signature_email: "carlos.mendoza@cotalo.com",
      signature_phone: "+52 55 9876 5432",
      signature_whatsapp: "+52 55 9876 5432",
      footer_text: "Creamos productos de alta calidad con materiales y procesos sustentables"
    )
    puts "✅ PDF Config creado para #{target_user.email}"
  end
else
  puts "❌ No se encontró usuario con email: gabrielreyesb@gmail.com"
end 