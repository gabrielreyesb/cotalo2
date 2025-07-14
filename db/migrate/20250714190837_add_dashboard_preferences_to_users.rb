class AddDashboardPreferencesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :dashboard_preferences, :text
  end
end
