class CreatePdfConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :pdf_configs do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :footer_text
      t.string :logo_url
      t.string :signature_name
      t.string :signature_email
      t.string :signature_phone
      t.string :signature_whatsapp
      t.string :sales_condition_1
      t.string :sales_condition_2
      t.string :sales_condition_3
      t.string :sales_condition_4
      t.timestamps
    end
  end
end 