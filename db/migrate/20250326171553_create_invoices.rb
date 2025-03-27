class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.references :quote, null: false, foreign_key: true
      t.string :facturama_id
      t.string :status
      t.decimal :total
      t.json :data

      t.timestamps
    end
  end
end
