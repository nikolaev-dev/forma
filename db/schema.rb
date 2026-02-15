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

ActiveRecord::Schema[8.1].define(version: 2026_02_15_500002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_user_id", null: false
    t.jsonb "after", default: {}
    t.jsonb "before", default: {}
    t.datetime "created_at", null: false
    t.inet "ip"
    t.bigint "record_id"
    t.string "record_type"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor_user_id"], name: "index_audit_logs_on_actor_user_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["record_type", "record_id"], name: "index_audit_logs_on_record_type_and_record_id"
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

  create_table "design_ratings", force: :cascade do |t|
    t.string "comment"
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.integer "score", null: false
    t.string "source", default: "user", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["design_id", "user_id"], name: "idx_design_ratings_user_unique", unique: true, where: "((source)::text = 'user'::text)"
    t.index ["design_id"], name: "index_design_ratings_on_design_id"
    t.index ["user_id"], name: "index_design_ratings_on_user_id"
  end

  create_table "design_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.string "source", default: "user", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["design_id", "tag_id"], name: "index_design_tags_on_design_id_and_tag_id", unique: true
    t.index ["design_id"], name: "index_design_tags_on_design_id"
    t.index ["tag_id"], name: "index_design_tags_on_tag_id"
  end

  create_table "designs", force: :cascade do |t|
    t.text "base_prompt"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.string "moderation_status", default: "ok", null: false
    t.decimal "popularity_score", precision: 10, scale: 4, default: "0.0"
    t.virtual "search_vector", type: :tsvector, as: "(setweight(to_tsvector('russian'::regconfig, (COALESCE(title, ''::character varying))::text), 'A'::\"char\") || setweight(to_tsvector('russian'::regconfig, COALESCE(base_prompt, ''::text)), 'B'::\"char\"))", stored: true
    t.string "slug"
    t.bigint "source_design_id"
    t.bigint "style_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "visibility", default: "private", null: false
    t.index ["moderation_status"], name: "index_designs_on_moderation_status"
    t.index ["popularity_score"], name: "index_designs_on_popularity_score"
    t.index ["search_vector"], name: "index_designs_on_search_vector", using: :gin
    t.index ["slug"], name: "index_designs_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["source_design_id"], name: "index_designs_on_source_design_id"
    t.index ["style_id"], name: "index_designs_on_style_id"
    t.index ["user_id"], name: "index_designs_on_user_id"
    t.index ["visibility"], name: "index_designs_on_visibility"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.bigint "user_id", null: false
    t.index ["design_id"], name: "index_favorites_on_design_id"
    t.index ["user_id", "design_id"], name: "index_favorites_on_user_id_and_design_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "fillings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "default_settings", default: {}
    t.string "filling_type", null: false
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["filling_type"], name: "index_fillings_on_filling_type"
    t.index ["slug"], name: "index_fillings_on_slug", unique: true
  end

  create_table "generation_passes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB"
    t.datetime "ends_at", null: false
    t.jsonb "fair_use", default: {}
    t.integer "price_cents", default: 10000, null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id", "status"], name: "index_generation_passes_on_user_id_and_status"
    t.index ["user_id"], name: "index_generation_passes_on_user_id"
  end

  create_table "generation_selections", force: :cascade do |t|
    t.bigint "anonymous_identity_id"
    t.datetime "created_at", null: false
    t.bigint "generation_id", null: false
    t.bigint "generation_variant_id", null: false
    t.bigint "user_id"
    t.index ["anonymous_identity_id"], name: "index_generation_selections_on_anonymous_identity_id"
    t.index ["generation_id"], name: "index_generation_selections_on_generation_id"
    t.index ["generation_variant_id"], name: "index_generation_selections_on_generation_variant_id"
    t.index ["user_id"], name: "index_generation_selections_on_user_id"
  end

  create_table "generation_variants", force: :cascade do |t|
    t.text "composed_prompt", null: false
    t.datetime "created_at", null: false
    t.string "error_code"
    t.text "error_message"
    t.bigint "generation_id", null: false
    t.string "kind", null: false
    t.string "mutation_summary"
    t.jsonb "mutation_tags_added", default: []
    t.jsonb "mutation_tags_removed", default: []
    t.string "provider_job_id"
    t.jsonb "provider_metadata", default: {}
    t.bigint "seed"
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.index ["generation_id", "kind"], name: "index_generation_variants_on_generation_id_and_kind", unique: true
    t.index ["generation_id"], name: "index_generation_variants_on_generation_id"
    t.index ["provider_job_id"], name: "index_generation_variants_on_provider_job_id"
    t.index ["status"], name: "index_generation_variants_on_status"
  end

  create_table "generations", force: :cascade do |t|
    t.bigint "anonymous_identity_id"
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.string "error_code"
    t.text "error_message"
    t.datetime "finished_at"
    t.jsonb "preset_snapshot", default: {}
    t.string "provider", null: false
    t.string "source", default: "create", null: false
    t.datetime "started_at"
    t.string "status", default: "created", null: false
    t.jsonb "tags_snapshot", default: {}
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["anonymous_identity_id"], name: "index_generations_on_anonymous_identity_id"
    t.index ["design_id"], name: "index_generations_on_design_id"
    t.index ["source"], name: "index_generations_on_source"
    t.index ["status"], name: "index_generations_on_status"
    t.index ["user_id"], name: "index_generations_on_user_id"
  end

  create_table "notebook_skus", force: :cascade do |t|
    t.jsonb "brand_elements", default: {}
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB", null: false
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.jsonb "specs", default: {}
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_notebook_skus_on_code", unique: true
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

  create_table "order_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_type", null: false
    t.jsonb "metadata", default: {}
    t.bigint "order_id", null: false
    t.string "status", default: "created"
    t.datetime "updated_at", null: false
    t.index ["order_id", "file_type"], name: "index_order_files_on_order_id_and_file_type"
    t.index ["order_id"], name: "index_order_files_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "design_id", null: false
    t.bigint "filling_id", null: false
    t.string "format"
    t.bigint "notebook_sku_id", null: false
    t.bigint "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.jsonb "settings_snapshot", default: {}
    t.integer "total_price_cents", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["design_id"], name: "index_order_items_on_design_id"
    t.index ["filling_id"], name: "index_order_items_on_filling_id"
    t.index ["notebook_sku_id"], name: "index_order_items_on_notebook_sku_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "anonymous_identity_id"
    t.string "barcode_type", default: "code128", null: false
    t.string "barcode_value", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB", null: false
    t.citext "customer_email"
    t.string "customer_name"
    t.string "customer_phone"
    t.text "notes"
    t.string "order_number", null: false
    t.text "production_notes"
    t.jsonb "shipping_address", default: {}
    t.integer "shipping_cents", default: 0, null: false
    t.string "shipping_method"
    t.string "status", default: "draft", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["anonymous_identity_id"], name: "index_orders_on_anonymous_identity_id"
    t.index ["barcode_value"], name: "index_orders_on_barcode_value", unique: true
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "captured_at"
    t.text "confirmation_url"
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB", null: false
    t.string "idempotence_key"
    t.bigint "payable_id", null: false
    t.string "payable_type", null: false
    t.string "provider", default: "yookassa", null: false
    t.string "provider_payment_id"
    t.jsonb "raw", default: {}
    t.string "status", default: "created", null: false
    t.datetime "updated_at", null: false
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable_type_and_payable_id"
    t.index ["provider_payment_id"], name: "index_payments_on_provider_payment_id", unique: true, where: "(provider_payment_id IS NOT NULL)"
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "prompt_versions", force: :cascade do |t|
    t.string "change_reason"
    t.bigint "changed_by_user_id"
    t.datetime "created_at", null: false
    t.string "diff_summary"
    t.jsonb "metadata", default: {}
    t.bigint "prompt_id", null: false
    t.text "text", null: false
    t.index ["changed_by_user_id"], name: "index_prompt_versions_on_changed_by_user_id"
    t.index ["prompt_id"], name: "index_prompt_versions_on_prompt_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "current_text", null: false
    t.bigint "design_id", null: false
    t.datetime "updated_at", null: false
    t.index ["design_id"], name: "index_prompts_on_design_id"
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

  create_table "usage_counters", force: :cascade do |t|
    t.bigint "anonymous_identity_id"
    t.datetime "created_at", null: false
    t.integer "generations_count", default: 0
    t.date "period", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["anonymous_identity_id", "period"], name: "idx_usage_counters_anon_period", unique: true, where: "(anonymous_identity_id IS NOT NULL)"
    t.index ["anonymous_identity_id"], name: "index_usage_counters_on_anonymous_identity_id"
    t.index ["user_id", "period"], name: "idx_usage_counters_user_period", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["user_id"], name: "index_usage_counters_on_user_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "app_settings", "users", column: "updated_by_user_id"
  add_foreign_key "audit_logs", "users", column: "actor_user_id"
  add_foreign_key "catalog_items", "catalog_sections"
  add_foreign_key "design_ratings", "designs"
  add_foreign_key "design_ratings", "users"
  add_foreign_key "design_tags", "designs"
  add_foreign_key "design_tags", "tags"
  add_foreign_key "designs", "designs", column: "source_design_id"
  add_foreign_key "designs", "styles"
  add_foreign_key "designs", "users"
  add_foreign_key "favorites", "designs"
  add_foreign_key "favorites", "users"
  add_foreign_key "generation_passes", "users"
  add_foreign_key "generation_selections", "anonymous_identities"
  add_foreign_key "generation_selections", "generation_variants"
  add_foreign_key "generation_selections", "generations"
  add_foreign_key "generation_selections", "users"
  add_foreign_key "generation_variants", "generations"
  add_foreign_key "generations", "anonymous_identities"
  add_foreign_key "generations", "designs"
  add_foreign_key "generations", "users"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "order_files", "orders"
  add_foreign_key "order_items", "designs"
  add_foreign_key "order_items", "fillings"
  add_foreign_key "order_items", "notebook_skus"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "anonymous_identities"
  add_foreign_key "orders", "users"
  add_foreign_key "prompt_versions", "prompts"
  add_foreign_key "prompt_versions", "users", column: "changed_by_user_id"
  add_foreign_key "prompts", "designs"
  add_foreign_key "style_tags", "styles"
  add_foreign_key "style_tags", "tags"
  add_foreign_key "tag_relations", "tags", column: "from_tag_id"
  add_foreign_key "tag_relations", "tags", column: "to_tag_id"
  add_foreign_key "tag_synonyms", "tags"
  add_foreign_key "tags", "tag_categories"
  add_foreign_key "usage_counters", "anonymous_identities"
  add_foreign_key "usage_counters", "users"
end
