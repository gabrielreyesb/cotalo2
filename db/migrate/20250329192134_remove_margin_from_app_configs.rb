class RemoveMarginFromAppConfigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :app_configs, :margin, :decimal
  end
end
