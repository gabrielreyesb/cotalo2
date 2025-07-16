#!/usr/bin/env ruby

# Test script to verify subscription freeze is working
require_relative 'config/environment'

puts "Testing subscription freeze functionality..."
puts "=" * 50

# Test with a sample user (or create one if needed)
user = User.first

if user
  puts "Testing with user: #{user.email}"
  puts "Current subscription status: #{user.subscription_status}"
  puts "Trial ends at: #{user.trial_ends_at}"
  puts "Subscription ends at: #{user.subscription_ends_at}"
  puts ""
  
  puts "Testing subscription_active?: #{user.subscription_active?}"
  puts "Testing subscription_expired?: #{user.subscription_expired?}"
  puts "Testing trial_days_remaining: #{user.trial_days_remaining}"
  puts "Testing subscription_days_remaining: #{user.subscription_days_remaining}"
  puts "Testing active_for_authentication?: #{user.active_for_authentication?}"
  puts ""
  
  # Test with expired dates
  puts "Testing with expired trial date..."
  original_trial_ends_at = user.trial_ends_at
  user.update(trial_ends_at: 1.day.ago)
  
  puts "Trial ends at (expired): #{user.trial_ends_at}"
  puts "Testing subscription_active?: #{user.subscription_active?}"
  puts "Testing subscription_expired?: #{user.subscription_expired?}"
  puts "Testing trial_days_remaining: #{user.trial_days_remaining}"
  puts "Testing active_for_authentication?: #{user.active_for_authentication?}"
  puts ""
  
  # Restore original date
  user.update(trial_ends_at: original_trial_ends_at)
  puts "Restored original trial end date"
  
else
  puts "No users found in database"
end

puts "=" * 50
puts "Test completed!" 