class RemoveUserIdFromUnits < ActiveRecord::Migration[7.1]
  def change
    remove_reference :units, :user, foreign_key: true, null: false
  end
end 