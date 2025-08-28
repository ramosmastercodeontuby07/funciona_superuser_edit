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

ActiveRecord::Schema[8.0].define(version: 2025_08_22_234459) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "class_types", force: :cascade do |t|
    t.string "name"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.date "enrollment_date"
    t.string "plan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_number"
    t.date "next_payment_date"
    t.string "search_number"
    t.text "fingerprint_template"
    t.string "fingerprint_algo"
    t.datetime "fingerprint_updated_at"
    t.boolean "fingerprint_enabled", default: true
    t.index ["client_number"], name: "index_customers_on_client_number", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.integer "order_id"
    t.integer "user_id"
    t.string "plan", null: false
    t.date "started_on", null: false
    t.date "ends_on", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "payment_method"
    t.boolean "paid", default: true, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "started_on"], name: "index_memberships_on_customer_id_and_started_on"
    t.index ["customer_id"], name: "index_memberships_on_customer_id"
    t.index ["order_id"], name: "index_memberships_on_order_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cost_at_sale", precision: 10, scale: 2
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.decimal "total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "payment_method", default: "efectivo", null: false
    t.index ["payment_method"], name: "index_orders_on_payment_method"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "payment_method IN ('efectivo','transferencia')", name: "orders_payment_method_check"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.decimal "amount"
    t.string "payment_method"
    t.string "category"
    t.string "description"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.integer "client_number"
    t.string "plan_type"
    t.integer "age"
    t.float "weight"
    t.decimal "cost", precision: 8, scale: 2, default: "0.0", null: false
    t.index ["customer_id"], name: "index_payments_on_customer_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.integer "stock"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.integer "product_section"
    t.decimal "cost", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cost_price", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["cost"], name: "index_products_on_cost"
    t.index ["product_section"], name: "index_products_on_product_section"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "normal", null: false
    t.string "secret_code", default: "", null: false
    t.text "fingerprint_template"
    t.string "fingerprint_algo"
    t.datetime "fingerprint_updated_at"
    t.boolean "fingerprint_enabled", default: true
    t.string "linux_username"
    t.string "fingerprint_device"
    t.index ["linux_username"], name: "index_users_on_linux_username"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "memberships", "customers"
  add_foreign_key "memberships", "orders"
  add_foreign_key "memberships", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "customers"
end
