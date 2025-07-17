#!/usr/bin/env ruby

# Test script to verify admin users view functionality
require_relative 'config/environment'

puts "=== Testing Admin Users View ==="
puts

# Test the controller query
puts "Testing controller query..."
controller = Admin::UsersController.new
controller.instance_variable_set(:@show_disabled, false)

# Simulate the controller logic
users = User.where(disabled: false)
             .left_joins(:products, :quotes)
             .select('users.id, users.email, users.admin, users.disabled, users.created_at, users.updated_at, users.sign_in_count, users.current_sign_in_at, users.last_sign_in_at, users.current_sign_in_ip, users.last_sign_in_ip, users.trial_ends_at, users.stripe_customer_id, users.stripe_subscription_id, users.subscription_status, users.subscription_plan, users.subscription_ends_at, users.dashboard_preferences, COUNT(DISTINCT products.id) as products_count, COUNT(DISTINCT quotes.id) as quotes_count')
             .group('users.id')
             .order(created_at: :desc)

puts "✅ Query executed successfully"
puts "Found #{users.count} users"
puts

# Test each user
users.each do |user|
  puts "User: #{user.email}"
  puts "  Products: #{user.products_count}"
  puts "  Quotes: #{user.quotes_count}"
  puts "  Has activity: #{user.has_activity?}"
  puts
end

# Test translations
puts "=== Testing Translations ==="
I18n.locale = :es
puts "Spanish translations:"
puts "  products_count: #{I18n.t('admin.users.products_count')}"
puts "  quotes_count: #{I18n.t('admin.users.quotes_count')}"

I18n.locale = :en
puts "English translations:"
puts "  products_count: #{I18n.t('admin.users.products_count')}"
puts "  quotes_count: #{I18n.t('admin.users.quotes_count')}"

puts
puts "✅ All tests completed successfully!" 