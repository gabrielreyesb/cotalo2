class AddAdminCommentToSuggestions < ActiveRecord::Migration[7.1]
  def change
    add_column :suggestions, :admin_comment, :text
  end
end 