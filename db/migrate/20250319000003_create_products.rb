class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :description, null: false
      t.json :data, null: false, default: {}
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :products, [:user_id, :description]
  end
end 