class AddUnitToExtras < ActiveRecord::Migration[7.1]
  def change
    add_reference :extras, :unit, foreign_key: true
  end
end 