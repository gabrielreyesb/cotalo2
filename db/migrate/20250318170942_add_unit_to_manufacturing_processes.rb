class AddUnitToManufacturingProcesses < ActiveRecord::Migration[7.1]
  def change
    add_reference :manufacturing_processes, :unit, null: true, foreign_key: true
  end
end
