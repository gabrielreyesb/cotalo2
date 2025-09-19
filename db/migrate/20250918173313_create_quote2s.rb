class CreateQuote2s < ActiveRecord::Migration[7.1]
  def change
    create_table :quote2s do |t|
      t.string :quote_number, null: false
      t.string :client_name, null: false
      t.string :client_company
      t.string :client_email, null: false
      t.string :client_phone
      t.string :description, null: false
      t.json :product_data, null: false, default: {}
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :quote2s, [:user_id, :quote_number], unique: true
    add_index :quote2s, [:user_id, :client_email]
  end
end
