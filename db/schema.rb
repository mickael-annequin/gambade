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

ActiveRecord::Schema[8.1].define(version: 2026_10_04_094518) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "activities", force: :cascade do |t|
    t.bigint "walk_id", null: false
    t.string "kind", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at", null: false
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["walk_id"], name: "index_activities_on_walk_id"
  end

  create_table "dogs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "breed"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_dogs_on_user_id"
  end

  create_table "encounters", force: :cascade do |t|
    t.bigint "walk_id", null: false
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.datetime "met_at", null: false
    t.string "dog_name"
    t.string "breed"
    t.string "mood"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "friend_id"
    t.index ["friend_id"], name: "index_encounters_on_friend_id"
    t.index ["walk_id", "met_at"], name: "index_encounters_on_walk_id_and_met_at"
    t.index ["walk_id"], name: "index_encounters_on_walk_id"
  end

  create_table "friends", force: :cascade do |t|
    t.bigint "dog_id", null: false
    t.string "name", null: false
    t.string "breed"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dog_id"], name: "index_friends_on_dog_id"
  end

  create_table "track_points", force: :cascade do |t|
    t.bigint "walk_id", null: false
    t.decimal "latitude", precision: 9, scale: 6, null: false
    t.decimal "longitude", precision: 9, scale: 6, null: false
    t.float "accuracy"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["walk_id", "recorded_at"], name: "index_track_points_on_walk_id_and_recorded_at"
    t.index ["walk_id"], name: "index_track_points_on_walk_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "walk_photos", force: :cascade do |t|
    t.bigint "walk_id", null: false
    t.datetime "taken_at"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["walk_id"], name: "index_walk_photos_on_walk_id"
  end

  create_table "walks", force: :cascade do |t|
    t.bigint "dog_id", null: false
    t.datetime "started_at", null: false
    t.integer "duration_seconds", null: false
    t.integer "distance_meters", default: 0, null: false
    t.integer "dogs_met_count", default: 0, null: false
    t.boolean "tracked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_id"
    t.string "moods", default: [], null: false, array: true
    t.text "comment"
    t.integer "weather_code"
    t.decimal "temperature_celsius", precision: 4, scale: 1
    t.decimal "precipitation_mm", precision: 5, scale: 1
    t.integer "wind_kmh"
    t.index ["client_id"], name: "index_walks_on_client_id", unique: true
    t.index ["dog_id", "started_at"], name: "index_walks_on_dog_id_and_started_at"
    t.index ["dog_id"], name: "index_walks_on_dog_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "walks"
  add_foreign_key "dogs", "users"
  add_foreign_key "encounters", "friends", on_delete: :nullify
  add_foreign_key "encounters", "walks"
  add_foreign_key "friends", "dogs"
  add_foreign_key "track_points", "walks"
  add_foreign_key "walk_photos", "walks"
  add_foreign_key "walks", "dogs"
end
