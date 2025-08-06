#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== PRUEBA DE SUBIDA DE LOGO A CLOUDINARY ==="

# Buscar el usuario
user = User.find_by(email: "gabrielreyesb+80@gmail.com")
puts "Usuario: #{user.email}"

# Verificar configuración actual
pdf_config = user.pdf_config
puts "Logo URL actual: #{pdf_config.logo_url}"

# Simular la subida de un logo de prueba
puts "\n=== SIMULANDO SUBIDA DE LOGO ==="

begin
  # Crear un archivo de prueba (simulando una imagen)
  test_file_path = "/tmp/test_logo.png"
  File.write(test_file_path, "fake image data")
  
  # Simular el archivo como si viniera de un formulario
  require 'rack/test'
  require 'tempfile'
  
  tempfile = Tempfile.new(['test_logo', '.png'])
  tempfile.write("fake image data")
  tempfile.rewind
  
  # Simular el objeto de archivo
  class MockUploadedFile
    attr_reader :tempfile, :content_type, :size
    
    def initialize(tempfile)
      @tempfile = tempfile
      @content_type = 'image/png'
      @size = tempfile.size
    end
  end
  
  mock_file = MockUploadedFile.new(tempfile)
  
  puts "Archivo de prueba creado: #{mock_file.content_type}, #{mock_file.size} bytes"
  
  # Intentar subir a Cloudinary
  puts "\nIntentando subir a Cloudinary..."
  
  result = Cloudinary::Uploader.upload(
    mock_file.tempfile,
    folder: "pdf_logos/#{user.id}",
    public_id: "logo_#{Time.current.to_i}",
    overwrite: true,
    resource_type: :auto
  )
  
  puts "✅ Subida exitosa a Cloudinary!"
  puts "URL resultante: #{result['secure_url']}"
  puts "Public ID: #{result['public_id']}"
  
  # Actualizar el pdf_config
  pdf_config.logo_url = result['secure_url']
  pdf_config.save!
  
  puts "✅ PDF Config actualizado con nueva URL"
  puts "Nueva logo URL: #{pdf_config.reload.logo_url}"
  
rescue => e
  puts "❌ Error en la subida: #{e.message}"
  puts e.backtrace.join("\n")
end

# Limpiar archivos temporales
tempfile&.close
tempfile&.unlink
File.delete(test_file_path) if File.exist?(test_file_path) 