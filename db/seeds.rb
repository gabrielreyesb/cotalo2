# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Note: Demo data (materials, processes, extras, price margins, and a test product) 
# is automatically created for new users in the User#setup_initial_data method.
#
# For development purposes, you can create a test user with all demo data:

if Rails.env.development?
  puts "Creating development test user..."
  
  # Create a test user if it doesn't exist
  test_user = User.find_or_create_by(email: 'test@example.com') do |user|
    user.password = 'password123'
    user.password_confirmation = 'password123'
  end
  
  puts "Test user created: #{test_user.email}"
  puts "Demo data includes:"
  puts "- #{test_user.materials.count} materials"
  puts "- #{test_user.manufacturing_processes.count} processes" 
  puts "- #{test_user.extras.count} extras"
  puts "- #{test_user.price_margins.count} price margins"
  puts "- #{test_user.products.count} products (including 'Producto de prueba')"
  puts ""
  puts "Login with: test@example.com / password123"
end

# Examples:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
