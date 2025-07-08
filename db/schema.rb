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

ActiveRecord::Schema[7.1].define(version: 2025_07_08_020324) do
  create_table "balance_payments", force: :cascade do |t|
    t.date "date"
    t.decimal "amount"
    t.string "description"
    t.string "category"
    t.string "cycle_month"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "person"
    t.string "country"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_balance_payments_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "empresa_descriptions", force: :cascade do |t|
    t.integer "empresa_id", null: false
    t.string "description", null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_empresa_descriptions_on_category_id"
    t.index ["empresa_id", "description"], name: "index_empresa_descriptions_on_empresa_id_and_description", unique: true
    t.index ["empresa_id"], name: "index_empresa_descriptions_on_empresa_id"
  end

  create_table "empresas", force: :cascade do |t|
    t.string "identificador"
    t.string "descripcion"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "categorization_status", default: "consistent", null: false
    t.index ["user_id", "descripcion"], name: "index_empresas_on_user_id_and_descripcion", unique: true
    t.index ["user_id", "identificador"], name: "index_empresas_on_user_id_and_identificador", unique: true
    t.index ["user_id"], name: "index_empresas_on_user_id"
  end

  create_table "saldo_histories", force: :cascade do |t|
    t.string "cycle_month"
    t.decimal "saldo"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_saldo_histories_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.integer "cycle_end_day"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "nombre"
    t.string "avatar_filename"
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.date "date"
    t.string "description"
    t.decimal "amount"
    t.string "transaction_type"
    t.string "person"
    t.string "company_code"
    t.string "country"
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cycle_month"
    t.integer "user_id", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "balance_payments", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "empresa_descriptions", "categories"
  add_foreign_key "empresa_descriptions", "empresas"
  add_foreign_key "empresas", "users"
  add_foreign_key "saldo_histories", "users"
  add_foreign_key "settings", "users"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
end
