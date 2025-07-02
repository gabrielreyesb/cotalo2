class AddWeightToMaterials < ActiveRecord::Migration[7.1]
  def change
    # Add weight field for materials with grs/m² unit (grams per square meter)
    add_column :materials, :weight, :decimal, precision: 10, scale: 2, comment: 'Weight in grams per square meter (grs/m²)'
  end
end
