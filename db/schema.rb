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

ActiveRecord::Schema[7.1].define(version: 2025_06_11_220650) do
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
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "empresas", force: :cascade do |t|
    t.string "identificador"
    t.string "descripcion"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.integer "cycle_end_day"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["category_id"], name: "index_transactions_on_category_id"
  end

  add_foreign_key "transactions", "categories"
end
