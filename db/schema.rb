# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_04_09_153846) do
  create_table "app_configs", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "value_type", default: "string"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_app_configs_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_app_configs_on_user_id"
  end

  create_table "extras", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "cost", precision: 10, scale: 2
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_id"
    t.index ["unit_id"], name: "index_extras_on_unit_id"
    t.index ["user_id"], name: "index_extras_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "quote_id", null: false
    t.string "facturama_id"
    t.string "status"
    t.decimal "total"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id"], name: "index_invoices_on_quote_id"
  end

  create_table "manufacturing_processes", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "cost", precision: 10, scale: 2
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_id"
    t.index ["unit_id"], name: "index_manufacturing_processes_on_unit_id"
    t.index ["user_id"], name: "index_manufacturing_processes_on_user_id"
  end

  create_table "materials", force: :cascade do |t|
    t.string "description"
    t.decimal "price", precision: 10, scale: 2
    t.string "client_description"
    t.string "resistance"
    t.decimal "ancho", precision: 10, scale: 2
    t.decimal "largo", precision: 10, scale: 2
    t.text "comments"
    t.integer "unit_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_materials_on_unit_id"
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "news", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "price_margins", force: :cascade do |t|
    t.decimal "min_price"
    t.decimal "max_price"
    t.decimal "margin_percentage"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_price_margins_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "description", null: false
    t.json "data", default: {}, null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "description"], name: "index_products_on_user_id_and_description"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "quote_products", force: :cascade do |t|
    t.integer "quote_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_quote_products_on_product_id"
    t.index ["quote_id"], name: "index_quote_products_on_quote_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.string "quote_number"
    t.string "project_name"
    t.string "customer_name"
    t.string "organization"
    t.string "email"
    t.string "telephone"
    t.text "comments"
    t.integer "user_id", null: false
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "app_configs", "users"
  add_foreign_key "extras", "units"
  add_foreign_key "extras", "users"
  add_foreign_key "invoices", "quotes"
  add_foreign_key "manufacturing_processes", "units"
  add_foreign_key "manufacturing_processes", "users"
  add_foreign_key "materials", "units"
  add_foreign_key "materials", "users"
  add_foreign_key "price_margins", "users"
  add_foreign_key "products", "users"
  add_foreign_key "quote_products", "products"
  add_foreign_key "quote_products", "quotes"
  add_foreign_key "quotes", "users"
end
