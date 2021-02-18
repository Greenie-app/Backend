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

ActiveRecord::Schema.define(version: 2020_12_15_000240) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "jwt_blacklist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_blacklist_on_jti"
  end

  create_table "logfiles", force: :cascade do |t|
    t.bigint "squadron_id", null: false
    t.integer "completed_files", default: 0, null: false
    t.integer "failed_files", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["squadron_id"], name: "index_logfiles_on_squadron_id"
  end

  create_table "passes", force: :cascade do |t|
    t.bigint "squadron_id", null: false
    t.bigint "pilot_id"
    t.datetime "time", null: false
    t.string "ship_name"
    t.string "aircraft_type"
    t.integer "grade", null: false
    t.decimal "score", precision: 2, scale: 1
    t.boolean "trap"
    t.integer "wire"
    t.string "notes"
    t.index ["pilot_id"], name: "index_passes_on_pilot_id"
    t.index ["squadron_id"], name: "index_passes_on_squadron_id"
  end

  create_table "pilots", force: :cascade do |t|
    t.bigint "squadron_id", null: false
    t.string "name", null: false
    t.index ["squadron_id", "name"], name: "index_pilots_on_squadron_id_and_name", unique: true
    t.index ["squadron_id"], name: "index_pilots_on_squadron_id"
  end

  create_table "squadrons", force: :cascade do |t|
    t.string "name", null: false
    t.string "username", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_squadrons_on_email", unique: true
    t.index ["reset_password_token"], name: "index_squadrons_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "logfiles", "squadrons", on_delete: :cascade
  add_foreign_key "passes", "pilots", on_delete: :cascade
  add_foreign_key "passes", "squadrons", on_delete: :cascade
  add_foreign_key "pilots", "squadrons", on_delete: :cascade
end
