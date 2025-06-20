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

ActiveRecord::Schema[7.1].define(version: 2025_06_17_022840) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "cities", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "prefecture_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prefecture_id", "name"], name: "index_cities_on_prefecture_id_and_name", unique: true
    t.index ["prefecture_id"], name: "index_cities_on_prefecture_id"
  end

  create_table "companions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companions_on_name", unique: true
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id"
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feelings", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feelings_on_name", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "prefecture_id", null: false
    t.bigint "city_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_locations_on_city_id"
    t.index ["prefecture_id"], name: "index_locations_on_prefecture_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.bigint "shop_id", null: false
    t.bigint "companion_id", null: false
    t.bigint "feeling_id", null: false
    t.bigint "visit_reason_id", null: false
    t.text "body"
    t.date "visit_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "post_image"
    t.integer "visits_count"
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["companion_id"], name: "index_posts_on_companion_id"
    t.index ["feeling_id"], name: "index_posts_on_feeling_id"
    t.index ["shop_id"], name: "index_posts_on_shop_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["visit_reason_id"], name: "index_posts_on_visit_reason_id"
  end

  create_table "prefectures", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_prefectures_on_name", unique: true
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_shops_on_location_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "visit_reasons", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_visit_reasons_on_name", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "visited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "count"
    t.bigint "shop_id"
    t.index ["shop_id"], name: "index_visits_on_shop_id"
    t.index ["user_id"], name: "index_visits_on_user_id"
  end

  add_foreign_key "cities", "prefectures"
  add_foreign_key "locations", "cities"
  add_foreign_key "locations", "prefectures"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "companions"
  add_foreign_key "posts", "feelings"
  add_foreign_key "posts", "shops"
  add_foreign_key "posts", "users"
  add_foreign_key "posts", "visit_reasons"
  add_foreign_key "shops", "locations"
  add_foreign_key "visits", "shops"
  add_foreign_key "visits", "users"
end
