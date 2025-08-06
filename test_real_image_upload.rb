#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== PRUEBA DE SUBIDA DE IMAGEN REAL ==="

# Buscar el usuario
user = User.find_by(email: "gabrielreyesb+80@gmail.com")
puts "Usuario: #{user.email}"

# Verificar configuración actual
pdf_config = user.pdf_config
puts "Logo URL actual: #{pdf_config.logo_url}"

# Crear una imagen PNG real usando MiniMagick o similar
puts "\n=== CREANDO IMAGEN REAL ==="

begin
  # Usar el logo existente de Cotalo como base
  logo_path = Rails.root.join('app', 'assets', 'images', 'Cotalo_logo.png')
  
  if File.exist?(logo_path)
    puts "✅ Usando logo existente: #{logo_path}"
    
    # Simular el archivo como si viniera de un formulario
    require 'tempfile'
    
    # Copiar el archivo real a un tempfile
    tempfile = Tempfile.new(['real_logo', '.png'])
    FileUtils.cp(logo_path, tempfile.path)
    tempfile.rewind
    
    # Simular el objeto de archivo
    class MockUploadedFile
      attr_reader :tempfile, :content_type, :size
      
      def initialize(tempfile)
        @tempfile = tempfile
        @content_type = 'image/png'
        @size = File.size(tempfile.path)
      end
    end
    
    mock_file = MockUploadedFile.new(tempfile)
    
    puts "Archivo real creado: #{mock_file.content_type}, #{mock_file.size} bytes"
    
    # Intentar subir a Cloudinary
    puts "\nIntentando subir imagen real a Cloudinary..."
    
    result = Cloudinary::Uploader.upload(
      mock_file.tempfile,
      folder: "pdf_logos/#{user.id}",
      public_id: "logo_real_#{Time.current.to_i}",
      overwrite: true,
      resource_type: :auto
    )
    
    puts "✅ Subida exitosa a Cloudinary!"
    puts "URL resultante: #{result['secure_url']}"
    puts "Public ID: #{result['public_id']}"
    puts "Tipo de recurso: #{result['resource_type']}"
    puts "Formato: #{result['format']}"
    
    # Actualizar el pdf_config
    pdf_config.logo_url = result['secure_url']
    pdf_config.save!
    
    puts "✅ PDF Config actualizado con nueva URL"
    puts "Nueva logo URL: #{pdf_config.reload.logo_url}"
    
    # Probar si la URL es accesible
    puts "\n=== PROBANDO ACCESIBILIDAD ==="
    require 'net/http'
    require 'uri'
    
    uri = URI(result['secure_url'])
    response = Net::HTTP.get_response(uri)
    
    puts "Status: #{response.code}"
    puts "Content-Type: #{response['content-type']}"
    puts "Content-Length: #{response['content-length']}"
    
    if response.code == '200'
      puts "✅ URL accesible correctamente"
    else
      puts "❌ URL no accesible"
    end
    
  else
    puts "❌ No se encontró el logo de Cotalo en: #{logo_path}"
  end
  
rescue => e
  puts "❌ Error en la subida: #{e.message}"
  puts e.backtrace.join("\n")
end

# Limpiar archivos temporales
tempfile&.close
tempfile&.unlink 