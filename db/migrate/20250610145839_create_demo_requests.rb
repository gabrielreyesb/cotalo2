class CreateDemoRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :demo_requests do |t|
      t.string :name
      t.string :email
      t.string :company
      t.string :phone
      t.text :message

      t.timestamps
    end
  end
end
