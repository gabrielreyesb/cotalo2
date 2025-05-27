class SetupTrialPeriodForExistingUsers < ActiveRecord::Migration[7.0]
  def up
    # Find all users who don't have trial_ends_at set and are not admins
    User.where(trial_ends_at: nil).where.not(admin: true).find_each do |user|
      # Set trial period to 14 days from now
      user.update(
        trial_ends_at: 14.days.from_now,
        subscription_status: 'trial'
      )
    end
  end

  def down
    # No need to revert this migration as it's just setting up initial data
  end
end 