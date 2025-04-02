class RemoveMarginFromAppConfigs < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:app_configs, :margin)
      remove_column :app_configs, :margin, :decimal
    end
  end
end
