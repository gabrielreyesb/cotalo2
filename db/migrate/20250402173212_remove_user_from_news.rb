class RemoveUserFromNews < ActiveRecord::Migration[7.0]
  def change
    remove_reference :news, :user, foreign_key: true
  end
end
