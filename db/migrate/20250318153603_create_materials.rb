class CreateMaterials < ActiveRecord::Migration[7.1]
  def change
    create_table :materials do |t|
      t.string :description
      t.decimal :price, precision: 10, scale: 2
      t.string :nombre
      t.string :especificaciones
      t.decimal :ancho, precision: 10, scale: 2
      t.decimal :largo, precision: 10, scale: 2
      t.text :comments
      t.references :unit, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
