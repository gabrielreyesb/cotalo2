class CreateUnits < ActiveRecord::Migration[7.1]
  def change
    create_table :units do |t|
      t.string :name
      t.string :abbreviation
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
