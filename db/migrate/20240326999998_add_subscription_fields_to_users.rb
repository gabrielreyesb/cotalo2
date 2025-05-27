class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:users, :trial_ends_at)
      add_column :users, :trial_ends_at, :datetime
    end
    unless column_exists?(:users, :stripe_customer_id)
      add_column :users, :stripe_customer_id, :string
    end
    unless column_exists?(:users, :stripe_subscription_id)
      add_column :users, :stripe_subscription_id, :string
    end
    unless column_exists?(:users, :subscription_status)
      add_column :users, :subscription_status, :string, default: 'trial'
    end
    unless column_exists?(:users, :subscription_plan)
      add_column :users, :subscription_plan, :string
    end
    unless column_exists?(:users, :subscription_ends_at)
      add_column :users, :subscription_ends_at, :datetime
    end
    
    # Add indexes if they don't exist
    unless index_exists?(:users, :stripe_customer_id)
      add_index :users, :stripe_customer_id, unique: true
    end
    unless index_exists?(:users, :stripe_subscription_id)
      add_index :users, :stripe_subscription_id, unique: true
    end
    unless index_exists?(:users, :subscription_status)
      add_index :users, :subscription_status
    end
  end
end 