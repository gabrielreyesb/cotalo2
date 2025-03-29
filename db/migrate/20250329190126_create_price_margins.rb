class CreatePriceMargins < ActiveRecord::Migration[7.1]
  def change
    create_table :price_margins do |t|
      t.decimal :min_price
      t.decimal :max_price
      t.decimal :margin_percentage
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
