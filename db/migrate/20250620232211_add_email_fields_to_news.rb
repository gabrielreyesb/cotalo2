class AddEmailFieldsToNews < ActiveRecord::Migration[7.1]
  def change
    add_column :news, :sent_via_email, :boolean
    add_column :news, :sent_at, :datetime
  end
end
