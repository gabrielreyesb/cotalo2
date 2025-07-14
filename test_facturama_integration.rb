#!/usr/bin/env ruby

# Test script for Facturama integration
# Run this in Rails console: rails runner test_facturama_integration.rb

puts "🧪 Testing Facturama Integration"
puts "=" * 50

# Check if we have a user with API key configured
user = User.first
if user.nil?
  puts "❌ No users found. Please create a user first."
  exit
end

api_key = AppConfig.get_facturama_api_key(user)
if api_key.blank?
  puts "❌ No Facturama API key configured for user: #{user.email}"
  puts "   Please configure the API key in Settings → API Configuration"
  exit
end

puts "✅ Found API key for user: #{user.email}"
puts "🔑 API Key format: #{api_key[0..10]}..."

# Test API connection
begin
  facturama = FacturamaService.new(api_key)
  result = facturama.verify_account
  
  if result[:success]
    puts "✅ API connection successful!"
    puts "📦 Found #{result[:products].length} products in Facturama"
    
    if result[:products].any?
      puts "   Sample products:"
      result[:products].first(3).each do |product|
        puts "   - #{product['Name']} (#{product['Price']})"
      end
    end
  else
    puts "❌ API connection failed: #{result[:error]}"
    exit
  end
rescue => e
  puts "❌ Error testing API: #{e.message}"
  exit
end

# Check for quotes
quotes = user.quotes.includes(:quote_products)
if quotes.empty?
  puts "⚠️  No quotes found. Please create a quote first to test invoice creation."
  puts "   You can create a quote at: http://localhost:3000/quotes/new"
else
  puts "✅ Found #{quotes.length} quotes"
  
  # Check for invoices
  invoices = Invoice.joins(:quote).where(quotes: { user: user })
  puts "📄 Found #{invoices.length} invoices"
  
  if invoices.any?
    puts "   Recent invoices:"
    invoices.last(3).each do |invoice|
      status_color = case invoice.status
                     when 'created' then '🟢'
                     when 'cancelled' then '🔴'
                     when 'pending' then '🟡'
                     else '⚪'
                     end
      puts "   #{status_color} Invoice ##{invoice.id} (#{invoice.status}) - Quote: #{invoice.quote.quote_number}"
    end
  end
end

puts "\n🎯 Next Steps:"
puts "1. Create a quote with products"
puts "2. Go to the quote show page"
puts "3. Click 'Create Invoice' button"
puts "4. Check the invoice status and Facturama integration"

puts "\n📋 Test URLs:"
puts "- Settings: http://localhost:3000/app_configs/edit"
puts "- New Quote: http://localhost:3000/quotes/new"
puts "- Quotes List: http://localhost:3000/quotes"

puts "\n✅ Facturama integration is ready for testing!" 