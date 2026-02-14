# 06. Хранилище — FORMA

> Версия: v0.1 | Дата: 2026-02-14

> **Конвенция:** Все enum-поля — только строчные (string), не integer.
> **Деньги:** integer в копейках (`*_cents`), `currency: "RUB"`.
> **Публичные ID:** HashID 6 символов (gem `hashid-rails`), вычисляется из `id`, не хранится в БД.
> **Публичные URL:** slug для сущностей с человекочитаемыми URL (styles, tags, designs, drops, fillings).
> **Файлы:** ActiveStorage + S3-compatible.

## 1. PostgreSQL Extensions

```ruby
enable_extension "citext"     # email
enable_extension "pg_trgm"    # поиск/подсказки
enable_extension "unaccent"   # поиск
```

## 1b. HashID (gem `hashid-rails`)

Для публичных URL используется HashID — короткий 6-символьный идентификатор, вычисляемый из `id` записи. **Не хранится в БД** — генерируется на лету.

```ruby
# Gemfile
gem "hashid-rails"

# config/initializers/hashid.rb
Hashid::Rails.configure do |config|
  config.salt = Rails.application.credentials.hashid_salt
  config.min_hash_length = 6
  config.alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
end

# В моделях, которым нужен публичный ID:
class Design < ApplicationRecord
  include Hashid::Rails
end

# Использование:
design.hashid        # => "k5dm8p"
Design.find(hashid)  # => #<Design id: 42>
```

**Где используется hashid:**
- `users` — профиль, API
- `designs` — публичные страницы (fallback если нет slug)
- `orders` — отслеживание заказа
- `generations` — статус генерации

**Где используется slug (человекочитаемый URL):**
- `styles` — `/styles/:slug`
- `tags` — фильтры, API
- `tag_categories` — фильтры
- `designs` — `/d/:slug` (приоритет над hashid)
- `drops` — `/drops/:slug`
- `fillings` — API
- `catalog_sections` — API

**Приоритет маршрутизации:** slug (если есть) > hashid.

## 2. Схема данных

### 2.1. users

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | hashid вычисляется из id (6 символов) |
| email | citext | UNIQUE (where NOT NULL) | Может быть NULL при OAuth |
| phone | string | UNIQUE (where NOT NULL) | |
| name | string | | |
| role | string | NOT NULL, DEFAULT "user" | `"user"`, `"creator"`, `"moderator"`, `"admin"` |
| status | string | NOT NULL, DEFAULT "active" | `"active"`, `"blocked"`, `"deleted"` |
| locale | string | NOT NULL, DEFAULT "ru" | |
| timezone | string | | |
| last_seen_at | datetime | | |
| metadata | jsonb | NOT NULL, DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.2. oauth_identities

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK | |
| provider | string | NOT NULL | `"vk"`, `"yandex"`, `"tbank"`, `"alfa"`, `"google"` |
| uid | string | NOT NULL | |
| access_token | text | encrypted | |
| refresh_token | text | encrypted | |
| expires_at | datetime | | |
| scopes | string | | |
| raw_profile | jsonb | NOT NULL, DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[provider, uid]`

### 2.3. anonymous_identities

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| anon_token_hash | string | NOT NULL, UNIQUE | Хэш cookie token |
| fingerprint_hash | string | | |
| last_ip | inet | | |
| last_seen_at | datetime | | |
| metadata | jsonb | DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.4. tag_categories

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | "Страны", "Сезоны"... |
| slug | string | NOT NULL, UNIQUE | |
| position | integer | NOT NULL, DEFAULT 0 | |
| is_active | boolean | NOT NULL, DEFAULT true | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.5. tags

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | |
| slug | string | NOT NULL, UNIQUE | |
| tag_category_id | bigint | NOT NULL, FK | |
| visibility | string | NOT NULL, DEFAULT "public" | `"public"`, `"hidden"` |
| kind | string | NOT NULL, DEFAULT "generic" | `"generic"`, `"brand_mood"` |
| weight | decimal(6,3) | NOT NULL, DEFAULT 1.0 | |
| is_banned | boolean | NOT NULL, DEFAULT false | |
| banned_reason | string | | |
| metadata | jsonb | NOT NULL, DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Index GIN trigram:** `name` (для автодополнения)

### 2.6. tag_synonyms

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| tag_id | bigint | NOT NULL, FK | |
| phrase | string | NOT NULL | Синоним |
| normalized | string | NOT NULL, UNIQUE | Для поиска |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.7. tag_relations

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| from_tag_id | bigint | NOT NULL, FK | |
| to_tag_id | bigint | NOT NULL, FK | |
| relation_type | string | NOT NULL | `"parent_of"`, `"related"`, `"conflicts_with"`, `"discouraged_with"` |
| weight | decimal(6,3) | DEFAULT 1.0 | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[from_tag_id, to_tag_id, relation_type]`

### 2.8. styles

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | |
| slug | string | NOT NULL, UNIQUE | |
| description | text | | |
| status | string | NOT NULL, DEFAULT "draft" | `"draft"`, `"published"`, `"hidden"` |
| position | integer | NOT NULL, DEFAULT 0 | |
| popularity_score | decimal(10,4) | NOT NULL, DEFAULT 0 | |
| generation_preset | jsonb | NOT NULL, DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

**ActiveStorage:** `cover_image`, `gallery_images[]`

### 2.9. style_tags (M2M)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| style_id | bigint | NOT NULL, FK | |
| tag_id | bigint | NOT NULL, FK | |
| is_primary | boolean | DEFAULT false | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[style_id, tag_id]`

### 2.10. catalog_sections

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | |
| slug | string | NOT NULL, UNIQUE | |
| section_type | string | NOT NULL, DEFAULT "editorial" | `"editorial"`, `"popular"`, `"new"`, `"drop"`, `"custom"` |
| is_active | boolean | NOT NULL, DEFAULT true | |
| position | integer | DEFAULT 0 | |
| rules | jsonb | DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.11. catalog_items

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| catalog_section_id | bigint | NOT NULL, FK | |
| item_type | string | NOT NULL | Polymorphic: "Style", "Design", "Drop" |
| item_id | bigint | NOT NULL | |
| position | integer | DEFAULT 0 | |
| pinned | boolean | DEFAULT false | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.12. designs

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | hashid вычисляется из id (6 символов) |
| user_id | bigint | FK (nullable) | NULL для системных/админских |
| source_design_id | bigint | FK (nullable) | Родитель для ремикса |
| title | string | | Авто или пользователь |
| slug | string | UNIQUE (where NOT NULL) | Публичный URL: `/d/:slug`, fallback на hashid |
| visibility | string | NOT NULL, DEFAULT "private" | `"private"`, `"unlisted"`, `"public"` |
| moderation_status | string | NOT NULL, DEFAULT "ok" | `"ok"`, `"requires_review"`, `"blocked"` |
| style_id | bigint | FK (nullable) | |
| base_prompt | text | | Последний промпт |
| metadata | jsonb | DEFAULT {} | |
| popularity_score | decimal(10,4) | DEFAULT 0 | |
| search_vector | tsvector | generated | Для full-text search |
| created_at | datetime | | |
| updated_at | datetime | | |

**Index GIN:** `search_vector`
**ActiveStorage:** `hero_image`, `share_image`

### 2.13. design_tags (M2M)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| design_id | bigint | NOT NULL, FK | |
| tag_id | bigint | NOT NULL, FK | |
| source | string | NOT NULL, DEFAULT "user" | `"user"`, `"system"`, `"admin"`, `"autotag"` |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[design_id, tag_id]`

### 2.14. prompts

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| design_id | bigint | NOT NULL, FK | |
| current_text | text | NOT NULL | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.15. prompt_versions

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| prompt_id | bigint | NOT NULL, FK | |
| text | text | NOT NULL | |
| changed_by_user_id | bigint | FK (nullable) | |
| change_reason | string | | "refine", "mutation", "remix" |
| diff_summary | string | | "gold->silver" |
| metadata | jsonb | DEFAULT {} | |
| created_at | datetime | | |

### 2.16. generations

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| design_id | bigint | NOT NULL, FK | |
| user_id | bigint | FK (nullable) | |
| anonymous_identity_id | bigint | FK (nullable) | |
| source | string | NOT NULL, DEFAULT "create" | `"create"`, `"refine"`, `"remix"`, `"admin_batch"` |
| status | string | NOT NULL, DEFAULT "created" | `"created"`, `"queued"`, `"running"`, `"partial"`, `"succeeded"`, `"failed"`, `"canceled"` |
| provider | string | NOT NULL | |
| preset_snapshot | jsonb | DEFAULT {} | |
| tags_snapshot | jsonb | DEFAULT {} | |
| error_code | string | | |
| error_message | text | | |
| started_at | datetime | | |
| finished_at | datetime | | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.17. generation_variants

3 записи на 1 generation (main, mutation_a, mutation_b).

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| generation_id | bigint | NOT NULL, FK | |
| kind | string | NOT NULL | `"main"`, `"mutation_a"`, `"mutation_b"` |
| status | string | NOT NULL, DEFAULT "created" | `"created"`, `"queued"`, `"running"`, `"succeeded"`, `"failed"` |
| composed_prompt | text | NOT NULL | Финальный промпт |
| seed | bigint | | |
| mutation_summary | string | | "gold->silver" |
| mutation_tags_added | jsonb | DEFAULT [] | |
| mutation_tags_removed | jsonb | DEFAULT [] | |
| provider_job_id | string | | ID задачи у провайдера |
| provider_metadata | jsonb | DEFAULT {} | |
| error_code | string | | |
| error_message | text | | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[generation_id, kind]`
**ActiveStorage:** `preview_image`, `mockup_image`, `hires_image`

### 2.18. generation_selections

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| generation_id | bigint | NOT NULL, FK | |
| generation_variant_id | bigint | NOT NULL, FK | |
| user_id | bigint | FK (nullable) | |
| anonymous_identity_id | bigint | FK (nullable) | |
| created_at | datetime | | |

### 2.19. design_ratings

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| design_id | bigint | NOT NULL, FK | |
| user_id | bigint | FK (nullable) | |
| source | string | NOT NULL, DEFAULT "user" | `"user"`, `"admin"` |
| score | integer | NOT NULL | 1..5 |
| comment | string | | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[design_id, user_id]` (where source = "user")

### 2.20. favorites

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK | |
| design_id | bigint | NOT NULL, FK | |
| created_at | datetime | | |

**Unique:** `[user_id, design_id]`

### 2.21. moderation_reports

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| reporter_user_id | bigint | FK (nullable) | |
| design_id | bigint | NOT NULL, FK | |
| reason | string | NOT NULL | enum |
| details | text | | |
| status | string | DEFAULT "open" | `"open"`, `"closed"` |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.22. fillings

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | |
| slug | string | NOT NULL, UNIQUE | |
| filling_type | string | NOT NULL | `"grid"`, `"ruled"`, `"dot"`, `"blank"`, `"planner_weekly"`, `"planner_daily"`, `"dated"` |
| is_active | boolean | DEFAULT true | |
| default_settings | jsonb | DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

**ActiveStorage:** `preview_spread_image`

### 2.23. filling_templates

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| filling_id | bigint | NOT NULL, FK | |
| name | string | | "A5 Ru default" |
| format | string | | "A5", "B5" |
| settings_schema | jsonb | DEFAULT {} | |
| renderer | string | | "prawn", "render_pdf_service" |
| is_active | boolean | DEFAULT true | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.24. notebook_skus

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| code | string | NOT NULL, UNIQUE | "base", "pro", "elite" |
| name | string | NOT NULL | "FORMA Base" |
| price_cents | integer | NOT NULL | |
| currency | string | NOT NULL, DEFAULT "RUB" | |
| is_active | boolean | DEFAULT true | |
| specs | jsonb | DEFAULT {} | Обложка/материал/финиш... |
| brand_elements | jsonb | DEFAULT {} | DNA Card? манифест? edition? |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.25. orders

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | hashid вычисляется из id (6 символов) |
| order_number | string | NOT NULL, UNIQUE | FORMA-2026-000123 |
| user_id | bigint | FK (nullable) | |
| anonymous_identity_id | bigint | FK (nullable) | |
| status | string | NOT NULL, DEFAULT "draft" | `"draft"`, `"awaiting_payment"`, `"paid"`, `"in_production"`, `"shipped"`, `"delivered"`, `"canceled"`, `"refunded"` |
| subtotal_cents | integer | NOT NULL, DEFAULT 0 | |
| shipping_cents | integer | NOT NULL, DEFAULT 0 | |
| total_cents | integer | NOT NULL, DEFAULT 0 | |
| currency | string | NOT NULL, DEFAULT "RUB" | |
| customer_name | string | | |
| customer_phone | string | | |
| customer_email | citext | | |
| shipping_method | string | | |
| shipping_address | jsonb | DEFAULT {} | |
| tracking_number | string | | |
| notes | text | | |
| barcode_value | string | NOT NULL, UNIQUE | |
| barcode_type | string | NOT NULL, DEFAULT "code128" | |
| production_notes | text | | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.26. order_items

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| order_id | bigint | NOT NULL, FK | |
| design_id | bigint | NOT NULL, FK | |
| notebook_sku_id | bigint | NOT NULL, FK | |
| filling_id | bigint | NOT NULL, FK | |
| quantity | integer | NOT NULL, DEFAULT 1 | |
| unit_price_cents | integer | NOT NULL | |
| total_price_cents | integer | NOT NULL | |
| format | string | | "A5", "B5" |
| settings_snapshot | jsonb | DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.27. payments (ЮKassa)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| payable_type | string | NOT NULL | "Order" / "GenerationPass" |
| payable_id | bigint | NOT NULL | |
| provider | string | NOT NULL, DEFAULT "yookassa" | |
| provider_payment_id | string | UNIQUE (where NOT NULL) | ID в YooKassa |
| status | string | NOT NULL, DEFAULT "created" | `"created"`, `"pending"`, `"succeeded"`, `"canceled"`, `"failed"`, `"refunded"` |
| amount_cents | integer | NOT NULL | |
| currency | string | NOT NULL, DEFAULT "RUB" | |
| idempotence_key | string | | |
| confirmation_url | text | | |
| captured_at | datetime | | |
| raw | jsonb | DEFAULT {} | Весь payload |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.28. order_files

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| order_id | bigint | NOT NULL, FK | |
| file_type | string | NOT NULL | `"cover_print_pdf"`, `"inner_print_pdf"`, `"dna_card_pdf"`, `"packing_slip_pdf"`, `"preview_pack_zip"` |
| status | string | DEFAULT "created" | `"created"`, `"rendering"`, `"ready"`, `"failed"` |
| metadata | jsonb | DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

**ActiveStorage:** `file`

### 2.29. generation_passes

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| user_id | bigint | FK (nullable) | |
| status | string | NOT NULL, DEFAULT "active" | `"active"`, `"expired"`, `"canceled"` |
| starts_at | datetime | NOT NULL | |
| ends_at | datetime | NOT NULL | |
| price_cents | integer | NOT NULL, DEFAULT 10000 | 100 ₽ |
| currency | string | DEFAULT "RUB" | |
| fair_use | jsonb | DEFAULT {} | Rate limits |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.30. usage_counters

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| user_id | bigint | FK (nullable) | |
| anonymous_identity_id | bigint | FK (nullable) | |
| period | date | NOT NULL | |
| generations_count | integer | DEFAULT 0 | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[user_id, period]` (where user_id NOT NULL)
**Unique:** `[anonymous_identity_id, period]` (where anonymous_identity_id NOT NULL)

### 2.31. drops

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | |
| slug | string | NOT NULL, UNIQUE | |
| status | string | DEFAULT "draft" | `"draft"`, `"published"`, `"closed"` |
| starts_at | datetime | | |
| ends_at | datetime | | |
| edition_limit | integer | | Например 300 |
| created_at | datetime | | |
| updated_at | datetime | | |

### 2.32. drop_items

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| drop_id | bigint | NOT NULL, FK | |
| design_id | bigint | NOT NULL, FK | |
| position | integer | DEFAULT 0 | |
| is_active | boolean | DEFAULT true | |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[drop_id, design_id]`

### 2.33. edition_assignments

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| drop_id | bigint | FK (nullable) | |
| design_id | bigint | NOT NULL, FK | |
| order_item_id | bigint | FK (nullable) | NULL до продажи |
| edition_number | integer | NOT NULL | 43 |
| edition_total | integer | | 300 |
| status | string | DEFAULT "reserved" | `"reserved"`, `"assigned"`, `"canceled"` |
| created_at | datetime | | |
| updated_at | datetime | | |

**Unique:** `[drop_id, edition_number]`

### 2.34. style_votes

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| user_id | bigint | FK (nullable) | |
| anonymous_identity_id | bigint | FK (nullable) | |
| style_id | bigint | NOT NULL, FK | |
| value | integer | NOT NULL | +1 like, -1 dislike |
| created_at | datetime | | |

**Unique:** `[style_id, user_id]` (where user_id NOT NULL)
**Unique:** `[style_id, anonymous_identity_id]` (where anonymous_identity_id NOT NULL)

### 2.35. user_tag_affinities (опционально)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| user_id | bigint | NOT NULL, FK | |
| tag_id | bigint | NOT NULL, FK | |
| weight | decimal(8,4) | NOT NULL, DEFAULT 0 | |
| updated_at | datetime | | |

**Unique:** `[user_id, tag_id]`

### 2.36. audit_logs

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| actor_user_id | bigint | NOT NULL, FK | |
| action | string | NOT NULL | "tag.create", "style.publish"... |
| record_type | string | | Polymorphic |
| record_id | bigint | | |
| before | jsonb | DEFAULT {} | |
| after | jsonb | DEFAULT {} | |
| ip | inet | | |
| created_at | datetime | | |

### 2.37. app_settings

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| key | string | NOT NULL, UNIQUE | |
| value | jsonb | NOT NULL, DEFAULT {} | |
| updated_by_user_id | bigint | FK (nullable) | |
| updated_at | datetime | | |

## 3. ActiveStorage (стандарт Rails)

Автоматически создаются:
- `active_storage_blobs`
- `active_storage_attachments`
- `active_storage_variant_records` (опционально)

## 4. Файловое хранилище (S3)

### 4.1. Структура бакета

```
forma-storage/
  styles/
    {style_id}/cover.jpg
    {style_id}/gallery/1.jpg, 2.jpg...
  generations/
    {generation_id}/
      {variant_kind}/
        preview.jpg
        mockup.jpg
        hires.png
  designs/
    {design_id}/
      hero.jpg
      share.jpg
  orders/
    {order_id}/
      cover_print.pdf
      inner_print.pdf
      dna_card.pdf
      packing_slip.pdf
  fillings/
    {filling_id}/preview_spread.jpg
```

### 4.2. Политики хранения

- **Превью/мокапы:** хранить всегда (дешево)
- **Hires:** можно удалять через N дней после заказа (или архивировать в cold storage)
- **Print PDF:** хранить минимум 1 год (для переизданий)
- **Thumbnails:** генерировать через ActiveStorage variants

## 5. Минимальный набор для MVP

**Обязательно:**
- users, oauth_identities, anonymous_identities
- tag_categories, tags, tag_synonyms, tag_relations
- styles, style_tags
- designs, design_tags
- generations, generation_variants, generation_selections
- fillings
- notebook_skus
- orders, order_items, payments, order_files
- generation_passes, usage_counters
- audit_logs, app_settings

**Можно отложить (фаза 2):**
- drops, drop_items, edition_assignments
- filling_templates (старт с хардкодом)
- user_tag_affinities (считать на лету)
- prompts, prompt_versions (если base_prompt на designs хватает)
- catalog_sections, catalog_items (захардкодить витрины)
