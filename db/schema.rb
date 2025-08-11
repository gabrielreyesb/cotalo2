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

ActiveRecord::Schema[7.1].define(version: 2025_08_08_190000) do
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

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "company"
    t.text "address"
    t.text "notes"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "email"], name: "index_customers_on_user_id_and_email", unique: true
    t.index ["user_id", "name"], name: "index_customers_on_user_id_and_name"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "demo_requests", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "company"
    t.string "phone"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "indirect_costs", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "cost", precision: 10, scale: 2
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_id"
    t.index ["unit_id"], name: "index_indirect_costs_on_unit_id"
    t.index ["user_id"], name: "index_indirect_costs_on_user_id"
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
    t.string "side", default: "front", null: false
    t.index ["unit_id"], name: "index_manufacturing_processes_on_unit_id"
    t.index ["user_id"], name: "index_manufacturing_processes_on_user_id"
  end

  create_table "materials", force: :cascade do |t|
    t.string "description"
    t.decimal "cost", precision: 10, scale: 2
    t.string "client_description"
    t.string "resistance"
    t.decimal "ancho", precision: 10, scale: 2
    t.decimal "largo", precision: 10, scale: 2
    t.text "comments"
    t.integer "unit_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 10, scale: 2
    t.index ["unit_id"], name: "index_materials_on_unit_id"
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "news", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sent_via_email"
    t.datetime "sent_at"
  end

  create_table "pdf_configs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "footer_text"
    t.string "logo_url"
    t.string "signature_name"
    t.string "signature_email"
    t.string "signature_phone"
    t.string "signature_whatsapp"
    t.string "sales_condition_1"
    t.string "sales_condition_2"
    t.string "sales_condition_3"
    t.string "sales_condition_4"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pdf_configs_on_user_id", unique: true
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

  create_table "suggestions", force: :cascade do |t|
    t.text "content", null: false
    t.integer "user_id"
    t.boolean "reviewed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "admin_comment"
    t.index ["user_id"], name: "index_suggestions_on_user_id"
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
    t.boolean "disabled", default: false, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "trial_ends_at"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status", default: "trial"
    t.string "subscription_plan"
    t.datetime "subscription_ends_at"
    t.text "dashboard_preferences"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
    t.index ["stripe_subscription_id"], name: "index_users_on_stripe_subscription_id", unique: true
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
  end

  add_foreign_key "app_configs", "users"
  add_foreign_key "customers", "users"
  add_foreign_key "indirect_costs", "units"
  add_foreign_key "indirect_costs", "users"
  add_foreign_key "invoices", "quotes"
  add_foreign_key "manufacturing_processes", "units"
  add_foreign_key "manufacturing_processes", "users"
  add_foreign_key "materials", "units"
  add_foreign_key "materials", "users"
  add_foreign_key "pdf_configs", "users"
  add_foreign_key "price_margins", "users"
  add_foreign_key "products", "users"
  add_foreign_key "quote_products", "products"
  add_foreign_key "quote_products", "quotes"
  add_foreign_key "quotes", "users"
  add_foreign_key "suggestions", "users"
end
