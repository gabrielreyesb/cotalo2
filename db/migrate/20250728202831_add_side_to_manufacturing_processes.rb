class AddSideToManufacturingProcesses < ActiveRecord::Migration[7.1]
  def change
    add_column :manufacturing_processes, :side, :string, default: 'front', null: false
  end
end
