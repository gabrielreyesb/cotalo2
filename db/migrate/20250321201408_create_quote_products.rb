class CreateQuoteProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :quote_products do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
