class RenameFieldsInMaterials < ActiveRecord::Migration[7.1]
  def change
    rename_column :materials, :nombre, :client_description
    rename_column :materials, :especificaciones, :resistance
  end
end
