class CreateAppConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :app_configs do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :app_configs, [:user_id, :key], unique: true
  end
end 