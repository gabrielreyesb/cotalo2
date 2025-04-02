class CreateNews < ActiveRecord::Migration[7.1]
  def change
    create_table :news do |t|
      t.string :title
      t.text :content
      t.datetime :published_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
