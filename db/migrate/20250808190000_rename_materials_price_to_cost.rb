class RenameMaterialsPriceToCost < ActiveRecord::Migration[7.1]
  # NOTE: This migration only renames the column. Run it when you're ready to switch views/API to :cost
  def up
    if column_exists?(:materials, :price) && !column_exists?(:materials, :cost)
      rename_column :materials, :price, :cost
    end
  end

  def down
    if column_exists?(:materials, :cost) && !column_exists?(:materials, :price)
      rename_column :materials, :cost, :price
    end
  end
end


