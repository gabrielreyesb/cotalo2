class AddDirectQuoteFieldsToQuotes < ActiveRecord::Migration[7.1]
  def change
    add_column :quotes, :description, :string
    add_column :quotes, :product_data, :json
  end
end
