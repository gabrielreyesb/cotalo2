namespace :users do
  desc 'Reset dashboard onboarding blocks (welcome/reminder) for a user by email'
  task :reset_dashboard_blocks, [:email] => :environment do |_, args|
    email = args[:email]
    unless email.present?
      puts 'Usage: rake users:reset_dashboard_blocks[email@example.com]'
      exit 1
    end

    user = User.find_by(email: email)
    if user.nil?
      puts "User not found: #{email}"
      exit 1
    end

    preferences = user.dashboard_preferences
    preferences.delete('welcome')
    preferences.delete('reminder')
    user.dashboard_preferences = preferences

    if user.save
      puts "Dashboard blocks reset for #{email}. The onboarding/reminder will show again if applicable."
    else
      puts "Failed to update user: #{user.errors.full_messages.join(', ')}"
      exit 1
    end
  end
end


