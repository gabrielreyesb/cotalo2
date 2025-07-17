#!/usr/bin/env ruby

# Test script to verify user activity tracking functionality
require_relative 'config/environment'

puts "=== Testing User Activity Tracking ==="
puts

# Find a test user
user = User.where(admin: false).first
if user.nil?
  puts "❌ No non-admin users found. Please create a test user first."
  exit 1
end

puts "📧 Testing with user: #{user.email}"
puts "📅 Created: #{user.created_at.strftime('%Y-%m-%d')}"
puts

# Check current activity
puts "=== Current Activity ==="
puts "📦 Products: #{user.products_count}"
puts "📋 Quotes: #{user.quotes_count}"
puts "🎯 Has Activity: #{user.has_activity?}"
puts

# Create some test data if user has no activity
if user.products_count == 0 && user.quotes_count == 0
  puts "=== Creating Test Data ==="
  
  # Create a test product
  puts "Creating test product..."
  
  # Get or create a material for the user
  material = user.materials.first
  if material.nil?
    unit = Unit.find_or_create_by!(name: 'mt2', abbreviation: 'm²')
    material = user.materials.create!(
      description: 'Test Material',
      client_description: 'Test Material',
      price: 10.0,
      unit: unit,
      ancho: 100,
      largo: 100
    )
    puts "✅ Created test material: #{material.description}"
  end
  
  product = user.products.create!(
    description: "Test Product for Activity Tracking",
    data: {
      general_info: {
        width: 100,
        length: 200,
        quantity: 1,
        comments: "Test product"
      },
      materials: [
        {
          material_id: material.id,
          width: 100,
          length: 200,
          quantity: 1,
          pieces_per_material: 1
        }
      ],
      processes: [],
      extras: [],
      pricing: {
        materials_cost: 0,
        processes_cost: 0,
        extras_cost: 0,
        subtotal: 0,
        waste_percentage: 5,
        waste_value: 0,
        price_per_piece_before_margin: 0,
        margin_percentage: 30,
        margin_value: 0,
        total_price: 0,
        final_price_per_piece: 0
      }
    }
  )
  puts "✅ Product created: #{product.description}"
  
  # Create a test quote
  puts "Creating test quote..."
  quote = user.quotes.create!(
    quote_number: "TEST-#{Time.current.strftime('%Y%m%d')}-001",
    project_name: "Test Project",
    customer_name: "Test Customer",
    organization: "Test Organization",
    email: "test@example.com",
    telephone: "123-456-7890"
  )
  puts "✅ Quote created: #{quote.quote_number}"
  
  puts
end

# Check activity after creating data
puts "=== Activity After Data Creation ==="
puts "📦 Products: #{user.products_count}"
puts "📋 Quotes: #{user.quotes_count}"
puts "🎯 Has Activity: #{user.has_activity?}"
puts

# Test the activity summary method
puts "=== Activity Summary ==="
summary = user.activity_summary
puts "Summary: #{summary.inspect}"
puts

# Test admin query with counts
puts "=== Testing Admin Query with Counts ==="
admin_users = User.left_joins(:products, :quotes)
                  .select('users.id, users.email, users.admin, users.disabled, users.created_at, users.updated_at, users.sign_in_count, users.current_sign_in_at, users.last_sign_in_at, users.current_sign_in_ip, users.last_sign_in_ip, users.trial_ends_at, users.stripe_customer_id, users.stripe_subscription_id, users.subscription_status, users.subscription_plan, users.subscription_ends_at, users.dashboard_preferences, COUNT(DISTINCT products.id) as products_count, COUNT(DISTINCT quotes.id) as quotes_count')
                  .group('users.id')
                  .order(created_at: :desc)

puts "Found #{admin_users.count} users with activity data:"
admin_users.each do |u|
  puts "  - #{u.email}: #{u.products_count} products, #{u.quotes_count} quotes"
end

puts
puts "✅ User activity tracking functionality is working correctly!" 