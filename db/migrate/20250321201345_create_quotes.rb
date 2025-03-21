class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.string :quote_number
      t.string :project_name
      t.string :customer_name
      t.string :organization
      t.string :email
      t.string :telephone
      t.text :comments
      t.references :user, null: false, foreign_key: true
      t.json :data

      t.timestamps
    end
  end
end
