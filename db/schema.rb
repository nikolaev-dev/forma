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

ActiveRecord::Schema[8.1].define(version: 2026_02_14_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "anonymous_identities", force: :cascade do |t|
    t.string "anon_token_hash", null: false
    t.datetime "created_at", null: false
    t.string "fingerprint_hash"
    t.inet "last_ip"
    t.datetime "last_seen_at"
    t.jsonb "metadata", default: {}
    t.datetime "updated_at", null: false
    t.index ["anon_token_hash"], name: "index_anonymous_identities_on_anon_token_hash", unique: true
  end

  create_table "app_settings", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "updated_at"
    t.bigint "updated_by_user_id"
    t.jsonb "value", default: {}, null: false
    t.index ["key"], name: "index_app_settings_on_key", unique: true
    t.index ["updated_by_user_id"], name: "index_app_settings_on_updated_by_user_id"
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "provider", null: false
    t.jsonb "raw_profile", default: {}, null: false
    t.text "refresh_token"
    t.string "scopes"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.citext "email"
    t.datetime "last_seen_at"
    t.string "locale", default: "ru", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.string "phone"
    t.string "role", default: "user", null: false
    t.string "status", default: "active", null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "app_settings", "users", column: "updated_by_user_id"
  add_foreign_key "oauth_identities", "users"
end
