#!/usr/bin/env ruby

puts "=== CREANDO ARCHIVO .env ==="
puts ""

# Contenido del archivo .env
env_content = <<~ENV_CONTENT
# Cloudinary Configuration
# Reemplaza estos valores con tus credenciales reales de Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Rails Environment
RAILS_ENV=development

# Database (si necesitas configurar la base de datos)
# DATABASE_URL=sqlite3:db/development.sqlite3

# Otras variables de entorno que puedas necesitar
# SECRET_KEY_BASE=your_secret_key_base
ENV_CONTENT

# Crear el archivo .env
File.write('.env', env_content)

puts "✅ Archivo .env creado exitosamente!"
puts ""
puts "📝 INSTRUCCIONES:"
puts "1. Abre el archivo .env con tu editor de texto"
puts "2. Reemplaza los valores de Cloudinary con tus credenciales reales:"
puts "   - CLOUDINARY_CLOUD_NAME=tu_cloud_name_real"
puts "   - CLOUDINARY_API_KEY=tu_api_key_real"
puts "   - CLOUDINARY_API_SECRET=tu_api_secret_real"
puts ""
puts "3. Guarda el archivo"
puts "4. Reinicia tu servidor Rails"
puts ""
puts "🔗 Para obtener tus credenciales de Cloudinary:"
puts "   - Ve a https://cloudinary.com/"
puts "   - Crea una cuenta gratuita"
puts "   - En tu dashboard, copia Cloud Name, API Key y API Secret"
puts ""
puts "📁 Ubicación del archivo: #{File.expand_path('.env')}" 