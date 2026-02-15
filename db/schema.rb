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

ActiveRecord::Schema[8.1].define(version: 2026_02_15_000008) do
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

  create_table "catalog_items", force: :cascade do |t|
    t.bigint "catalog_section_id", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.boolean "pinned", default: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["catalog_section_id"], name: "index_catalog_items_on_catalog_section_id"
    t.index ["item_type", "item_id"], name: "index_catalog_items_on_item_type_and_item_id"
    t.index ["position"], name: "index_catalog_items_on_position"
  end

  create_table "catalog_sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.jsonb "rules", default: {}
    t.string "section_type", default: "editorial", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_catalog_sections_on_position"
    t.index ["section_type"], name: "index_catalog_sections_on_section_type"
    t.index ["slug"], name: "index_catalog_sections_on_slug", unique: true
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

  create_table "style_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false
    t.bigint "style_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["style_id", "tag_id"], name: "index_style_tags_on_style_id_and_tag_id", unique: true
    t.index ["style_id"], name: "index_style_tags_on_style_id"
    t.index ["tag_id"], name: "index_style_tags_on_tag_id"
  end

  create_table "styles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "generation_preset", default: {}, null: false
    t.string "name", null: false
    t.decimal "popularity_score", precision: 10, scale: 4, default: "0.0", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["popularity_score"], name: "index_styles_on_popularity_score"
    t.index ["position"], name: "index_styles_on_position"
    t.index ["slug"], name: "index_styles_on_slug", unique: true
    t.index ["status"], name: "index_styles_on_status"
  end

  create_table "tag_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_tag_categories_on_position"
    t.index ["slug"], name: "index_tag_categories_on_slug", unique: true
  end

  create_table "tag_relations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "from_tag_id", null: false
    t.string "relation_type", null: false
    t.bigint "to_tag_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 6, scale: 3, default: "1.0"
    t.index ["from_tag_id", "to_tag_id", "relation_type"], name: "idx_tag_relations_unique", unique: true
    t.index ["from_tag_id"], name: "index_tag_relations_on_from_tag_id"
    t.index ["to_tag_id"], name: "index_tag_relations_on_to_tag_id"
  end

  create_table "tag_synonyms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "normalized", null: false
    t.string "phrase", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized"], name: "index_tag_synonyms_on_normalized", unique: true
    t.index ["tag_id"], name: "index_tag_synonyms_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "banned_reason"
    t.datetime "created_at", null: false
    t.boolean "is_banned", default: false, null: false
    t.string "kind", default: "generic", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "tag_category_id", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.decimal "weight", precision: 6, scale: 3, default: "1.0", null: false
    t.index ["is_banned"], name: "index_tags_on_is_banned"
    t.index ["kind"], name: "index_tags_on_kind"
    t.index ["name"], name: "index_tags_on_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["slug"], name: "index_tags_on_slug", unique: true
    t.index ["tag_category_id"], name: "index_tags_on_tag_category_id"
    t.index ["visibility"], name: "index_tags_on_visibility"
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
  add_foreign_key "catalog_items", "catalog_sections"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "style_tags", "styles"
  add_foreign_key "style_tags", "tags"
  add_foreign_key "tag_relations", "tags", column: "from_tag_id"
  add_foreign_key "tag_relations", "tags", column: "to_tag_id"
  add_foreign_key "tag_synonyms", "tags"
  add_foreign_key "tags", "tag_categories"
end
