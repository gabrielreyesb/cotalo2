class AddOnboardingFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :string
    add_column :users, :company, :string
    add_column :users, :phone, :string
  end
end


