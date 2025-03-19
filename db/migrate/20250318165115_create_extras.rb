class CreateExtras < ActiveRecord::Migration[7.1]
  def change
    create_table :extras do |t|
      t.string :name
      t.text :description
      t.decimal :cost, precision: 10, scale: 2
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
