class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :trial_ends_at, :datetime
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :subscription_status, :string, default: 'trial'
    add_column :users, :subscription_plan, :string
    add_column :users, :subscription_ends_at, :datetime
    
    add_index :users, :stripe_customer_id, unique: true
    add_index :users, :stripe_subscription_id, unique: true
    add_index :users, :subscription_status
  end
end
