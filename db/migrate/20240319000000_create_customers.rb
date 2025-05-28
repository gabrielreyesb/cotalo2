class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :company
      t.text :address
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :customers, [:user_id, :email], unique: true
    add_index :customers, [:user_id, :name]
  end
end 