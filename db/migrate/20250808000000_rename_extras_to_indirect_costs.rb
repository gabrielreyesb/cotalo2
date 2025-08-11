class RenameExtrasToIndirectCosts < ActiveRecord::Migration[7.1]
  def up
    if table_exists?(:extras) && !table_exists?(:indirect_costs)
      rename_table :extras, :indirect_costs
    end
  end

  def down
    if table_exists?(:indirect_costs) && !table_exists?(:extras)
      rename_table :indirect_costs, :extras
    end
  end
end


