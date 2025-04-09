class CreateSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :suggestions do |t|
      t.text :content, null: false
      t.references :user, foreign_key: true
      t.boolean :reviewed, default: false
      t.timestamps
    end
  end
end 