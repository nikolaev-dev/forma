# 06. Хранилище — FORMA

> Версия: v0.2 | Дата: 2026-02-15

> **Конвенция:** Все enum-поля — только строчные (string), не integer.
> **Деньги:** integer в копейках (`*_cents`), `currency: "RUB"`.
> **Публичные ID:** HashID 6 символов (gem `hashid-rails`), вычисляется из `id`, не хранится в БД.
> **Публичные URL:** slug для сущностей с человекочитаемыми URL (styles, tags, designs, drops, fillings, collections).
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
- `collections` — `/collections/:slug` (NEW v0.2)
- `fillings` — API
- `catalog_sections` — API

**Приоритет маршрутизации:** slug (если есть) > hashid.

---

## 2. Схема данных

### Таблицы из v0.1 (без изменений)

Следующие таблицы не изменились в v0.2:

- **2.1. users** — без изменений
- **2.2. oauth_identities** — без изменений
- **2.3. anonymous_identities** — без изменений
- **2.4. tag_categories** — без изменений
- **2.5. tags** — без изменений
- **2.6. tag_synonyms** — без изменений
- **2.7. tag_relations** — без изменений
- **2.8. styles** — без изменений
- **2.9. style_tags** — без изменений
- **2.10. catalog_sections** — добавлен section_type "collection" (см. ниже)
- **2.11. catalog_items** — polymorphic: "Style", "Design", "Drop", "Collection" (добавлен)
- **2.13. design_tags** — без изменений
- **2.14. prompts** — без изменений
- **2.15. prompt_versions** — без изменений
- **2.16. generations** — добавлен source "training_pipeline" (см. ниже)
- **2.18. generation_selections** — без изменений
- **2.19. design_ratings** — без изменений
- **2.20. favorites** — без изменений
- **2.21. moderation_reports** — без изменений
- **2.22. fillings** — без изменений
- **2.23. filling_templates** — без изменений
- **2.27. payments** — без изменений
- **2.28. order_files** — без изменений
- **2.29. generation_passes** — без изменений
- **2.30. usage_counters** — без изменений
- **2.34. style_votes** — без изменений
- **2.35. user_tag_affinities** — без изменений
- **2.36. audit_logs** — без изменений
- **2.37. app_settings** — без изменений

> Полную схему неизменённых таблиц см. в `docs/v0.1/06-storage.md`.

---

### Изменённые таблицы (v0.2)

#### 2.10. catalog_sections (изменение)

Добавлен section_type `"collection"`:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| section_type | string | NOT NULL, DEFAULT "editorial" | `"editorial"`, `"popular"`, `"new"`, `"drop"`, `"collection"`, `"custom"` |

#### 2.11. catalog_items (изменение)

Добавлен polymorphic type `"Collection"`:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| item_type | string | NOT NULL | Polymorphic: `"Style"`, `"Design"`, `"Drop"`, `"Collection"` |

#### 2.12. designs (изменение)

Добавлено поле `collection_id`:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | hashid вычисляется из id (6 символов) |
| user_id | bigint | FK (nullable) | NULL для системных/админских |
| source_design_id | bigint | FK (nullable) | Родитель для ремикса |
| **collection_id** | **bigint** | **FK (nullable)** | **Коллекция, к которой принадлежит дизайн (NEW v0.2)** |
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

#### 2.16. generations (изменение)

Добавлен source `"training_pipeline"`:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| source | string | NOT NULL, DEFAULT "create" | `"create"`, `"refine"`, `"remix"`, `"admin_batch"`, `"training_pipeline"` |

#### 2.17. generation_variants (изменение)

Добавлено поле `tier`:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| generation_id | bigint | NOT NULL, FK | |
| kind | string | NOT NULL | `"main"`, `"mutation_a"`, `"mutation_b"` |
| **tier** | **string** | **nullable** | **`"core"`, `"signature"`, `"lux"`, NULL (для обычных генераций без tier)** |
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

**Unique:** `[generation_id, kind]` (для обычных генераций, tier=NULL)
**Unique:** `[generation_id, kind, tier]` (для tier-генераций)
**ActiveStorage:** `preview_image`, `mockup_image`, `hires_image`

> **Две оси:** `kind` (main/mutation_a/mutation_b) и `tier` (core/signature/lux).
> Для пользовательских генераций: 3 варианта (3 kind × tier=NULL).
> Для training pipeline: до 9 вариантов (3 kind × 3 tier), или 3 варианта (kind=main × 3 tier) без мутаций.

#### 2.24. notebook_skus (изменение)

Переименование тарифов:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| code | string | NOT NULL, UNIQUE | `"core"`, `"signature"`, `"lux"` (было: base/pro/elite) |
| name | string | NOT NULL | "FORMA Core", "FORMA Signature", "FORMA Lux" |
| price_cents | integer | NOT NULL | TBD (определяется позже) |
| currency | string | NOT NULL, DEFAULT "RUB" | |
| is_active | boolean | DEFAULT true | |
| specs | jsonb | DEFAULT {} | Производственные параметры: обложка, печать, лак, тиснение, фурнитура... |
| brand_elements | jsonb | DEFAULT {} | Identity элементы по уровню: шильд, закладки, торец, карточка |
| created_at | datetime | | |
| updated_at | datetime | | |

**specs jsonb — пример для Lux:**
```json
{
  "cover": "real_leather",
  "lamination": null,
  "wave_treatment": "embossing_doming",
  "uv_varnish": false,
  "embossing": "multi_level",
  "metal_hardware": true,
  "closure": "magnetic_flap",
  "bookmark_tips": "hex_metal",
  "edge_paint": "gold_pearl",
  "paper_gsm": 140,
  "binding": "sewn_lay_flat",
  "packaging": "premium_gift_box"
}
```

#### 2.25. orders (без изменений)

Без изменений структуры.

#### 2.26. order_items (изменение)

Добавлено поле `tier`:

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| order_id | bigint | NOT NULL, FK | |
| design_id | bigint | NOT NULL, FK | |
| notebook_sku_id | bigint | NOT NULL, FK | |
| filling_id | bigint | NOT NULL, FK | |
| **tier** | **string** | **NOT NULL** | **`"core"`, `"signature"`, `"lux"` (NEW v0.2)** |
| quantity | integer | NOT NULL, DEFAULT 1 | |
| unit_price_cents | integer | NOT NULL | |
| total_price_cents | integer | NOT NULL | |
| format | string | | "A5", "B5" |
| settings_snapshot | jsonb | DEFAULT {} | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### 2.31. drops (без структурных изменений)

Таблица drops без изменений (уже была в v0.1):

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | |
| slug | string | NOT NULL, UNIQUE | |
| **collection_id** | **bigint** | **FK (nullable)** | **Привязка к коллекции (NEW v0.2)** |
| status | string | DEFAULT "draft" | `"draft"`, `"published"`, `"closed"` |
| starts_at | datetime | | |
| ends_at | datetime | | |
| edition_limit | integer | | Например 300 |
| created_at | datetime | | |
| updated_at | datetime | | |

#### 2.32-2.33. drop_items, edition_assignments

Без изменений (уже были в v0.1).

---

### Новые таблицы (v0.2)

#### 2.38. collections (NEW)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | "Японские мотивы", "Ботаника" |
| slug | string | NOT NULL, UNIQUE | `/collections/:slug` |
| description | text | | |
| collection_type | string | NOT NULL, DEFAULT "regular" | `"regular"`, `"limited"` |
| edition_size | integer | nullable | Только для limited: общий тираж (например 30) |
| stock_remaining | integer | nullable | Только для limited: сколько осталось |
| is_active | boolean | NOT NULL, DEFAULT true | |
| position | integer | NOT NULL, DEFAULT 0 | |
| created_at | datetime | | |
| updated_at | datetime | | |

**ActiveStorage:** `cover_image`

**Index:** `slug` (unique)

> **regular** — без ограничения тиража. **limited** — тираж N шт, stock_remaining декрементируется при покупке.

#### 2.39. tier_modifiers (NEW)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| tier | string | NOT NULL, UNIQUE | `"core"`, `"signature"`, `"lux"` |
| prompt_modifier | text | NOT NULL | Производственные детали для промпта |
| identity_elements | text | | Описание identity-элементов для промпта |
| negative_prompt | text | | Общий negative prompt |
| settings | jsonb | NOT NULL, DEFAULT {} | `{ aspect_ratio, lens, style_notes }` |
| created_at | datetime | | |
| updated_at | datetime | | |

**Seed-данные:**

```ruby
# Core
TierModifier.create!(
  tier: "core",
  prompt_modifier: "Coated paper wrap cover (NOT leather), matte lamination, flat printed wave (no UV, no embossing), simple elastic band, two plain ribbon bookmarks, no metal hardware, no badge, clean minimal product",
  identity_elements: "Two plain ribbon bookmarks, one chamfered 45-degree top-right corner, simple FORMA card in back pocket",
  negative_prompt: "cartoon, illustration, CGI look, low poly, fantasy shapes, melted materials, bad stitching, crooked edges, warped perspective, blurry, low resolution, noisy grain, harsh flash, oversaturated, plastic toy look, visible brand logos, readable text, watermarks, hands, people, cluttered background, unrealistic reflections, misaligned bookmarks, extra straps, extra corners chamfered, deformed hexagon",
  settings: { aspect_ratio: "2:3", lens: "50mm", style_notes: "photorealistic, manufacturable details, high micro-texture fidelity" }
)

# Signature
TierModifier.create!(
  tier: "signature",
  prompt_modifier: "Soft-touch paper cover with visible matte texture, spot UV / 3D varnish ONLY on the wave area (visible wet gloss shimmer), blind embossed small logo, two ribbon bookmarks, standard elastic strap, no metal parts",
  identity_elements: "Blind embossed hexagonal badge, two ribbon bookmarks, one chamfered 45-degree top-right corner, personalized FORMA card in back pocket",
  negative_prompt: "...(same as core)...",
  settings: { aspect_ratio: "2:3", lens: "50mm", style_notes: "photorealistic, manufacturable details, high micro-texture fidelity" }
)

# Lux
TierModifier.create!(
  tier: "lux",
  prompt_modifier: "Real leather cover with visible natural grain, deep multi-level embossed wave with domed resin lens inlay (glass-like surface), polished faceted hexagonal metal badge on magnetic flap closure, two ribbon bookmarks with small hex metal tips, painted edge (gold/pearl tint), premium rigid gift box nearby",
  identity_elements: "Polished metal hexagonal badge, two ribbon bookmarks with hex metal tips, one chamfered 45-degree top-right corner, numbered collector passport in back pocket",
  negative_prompt: "...(same as core)...",
  settings: { aspect_ratio: "2:3", lens: "50mm", style_notes: "photorealistic, manufacturable details, high micro-texture fidelity, leather grain, stitching, edge paint, metal reflections" }
)
```

#### 2.40. training_batches (NEW)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| name | string | NOT NULL | "Партия 2026-02: японские мотивы" |
| status | string | NOT NULL, DEFAULT "uploaded" | `"uploaded"`, `"processing"`, `"completed"` |
| images_count | integer | NOT NULL, DEFAULT 0 | |
| created_by_user_id | bigint | NOT NULL, FK | Администратор, загрузивший партию |
| created_at | datetime | | |
| updated_at | datetime | | |

**State machine:**
```
uploaded → processing → completed
```

#### 2.41. reference_images (NEW)

| Поле | Тип | Constraints | Описание |
|------|-----|------------|----------|
| id | bigint | PK | |
| training_batch_id | bigint | NOT NULL, FK | |
| status | string | NOT NULL, DEFAULT "uploaded" | `"uploaded"`, `"analyzing"`, `"analyzed"`, `"curated"`, `"generated"`, `"published"`, `"rejected"` |
| ai_analysis_claude | jsonb | DEFAULT {} | Результат Claude Vision |
| ai_analysis_openai | jsonb | DEFAULT {} | Результат GPT-4V (A/B тест) |
| selected_provider | string | nullable | `"claude"`, `"openai"` — какой промпт выбрал куратор |
| curated_prompt | text | nullable | Финальный промпт после правки куратором |
| collection_id | bigint | FK (nullable) | Назначенная коллекция |
| design_id | bigint | FK (nullable) | Созданный Design (после генерации + публикации) |
| curator_notes | text | | |
| created_at | datetime | | |
| updated_at | datetime | | |

**ActiveStorage:** `original_image`

**State machine:**
```
uploaded → analyzing → analyzed → curated → generated → published
                                          ↘ rejected
                        analyzed → rejected
```

**ai_analysis jsonb — структура:**
```json
{
  "description": "Обложка с японским садом, осенние клёны, пруд с карпами кои",
  "base_prompt": "Japanese zen garden in autumn, red maple trees reflecting in koi pond, stone lantern, misty atmosphere",
  "suggested_tags": ["japan", "autumn", "nature", "garden", "warm", "watercolor"],
  "mood": "serene",
  "dominant_colors": ["#8B0000", "#FFD700", "#2F4F4F"],
  "visual_style": "watercolor illustration",
  "complexity": "high",
  "suggested_collection": "Восточная коллекция"
}
```

---

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
      {variant_kind}_{tier}/         ← NEW v0.2 (для tier-генераций)
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
  collections/                        ← NEW v0.2
    {collection_id}/cover.jpg
  training/                           ← NEW v0.2
    {training_batch_id}/
      {reference_image_id}/original.jpg
```

### 4.2. Политики хранения

- **Превью/мокапы:** хранить всегда (дешево)
- **Hires:** можно удалять через N дней после заказа (или архивировать в cold storage)
- **Print PDF:** хранить минимум 1 год (для переизданий)
- **Thumbnails:** генерировать через ActiveStorage variants
- **Training originals:** хранить постоянно (стоимость AI-анализа выше хранения)

## 5. Миграции v0.2 (порядок)

```
1. CreateCollections           — таблица collections
2. AddCollectionIdToDesigns    — designs.collection_id FK
3. AddCollectionIdToDrops      — drops.collection_id FK
4. CreateTierModifiers         — таблица tier_modifiers
5. AddTierToGenerationVariants — generation_variants.tier
6. AddTierToOrderItems         — order_items.tier
7. UpdateNotebookSkuCodes      — переименование base→core, pro→signature, elite→lux
8. CreateTrainingBatches       — таблица training_batches
9. CreateReferenceImages       — таблица reference_images
10. AddCollectionSectionType   — catalog_sections: добавить "collection" в section_type
11. AddTrainingPipelineSource  — generations: добавить "training_pipeline" в source
```

## 6. Минимальный набор для v0.2

**Из v0.1 (уже есть):**
- users, oauth_identities, anonymous_identities
- tag_categories, tags, tag_synonyms, tag_relations
- styles, style_tags
- designs, design_tags
- generations, generation_variants, generation_selections
- fillings, filling_templates
- notebook_skus
- orders, order_items, payments, order_files
- generation_passes, usage_counters
- drops, drop_items, edition_assignments
- audit_logs, app_settings
- catalog_sections, catalog_items

**Новое в v0.2:**
- collections (+ designs.collection_id, drops.collection_id)
- tier_modifiers
- generation_variants.tier
- order_items.tier
- training_batches
- reference_images

## 7. Полный список таблиц (v0.2)

| # | Таблица | Статус v0.2 |
|---|---------|-------------|
| 1 | users | без изменений |
| 2 | oauth_identities | без изменений |
| 3 | anonymous_identities | без изменений |
| 4 | tag_categories | без изменений |
| 5 | tags | без изменений |
| 6 | tag_synonyms | без изменений |
| 7 | tag_relations | без изменений |
| 8 | styles | без изменений |
| 9 | style_tags | без изменений |
| 10 | catalog_sections | + section_type "collection" |
| 11 | catalog_items | + item_type "Collection" |
| 12 | designs | + collection_id FK |
| 13 | design_tags | без изменений |
| 14 | prompts | без изменений |
| 15 | prompt_versions | без изменений |
| 16 | generations | + source "training_pipeline" |
| 17 | generation_variants | + tier (string, nullable) |
| 18 | generation_selections | без изменений |
| 19 | design_ratings | без изменений |
| 20 | favorites | без изменений |
| 21 | moderation_reports | без изменений |
| 22 | fillings | без изменений |
| 23 | filling_templates | без изменений |
| 24 | notebook_skus | code: core/signature/lux |
| 25 | orders | без изменений |
| 26 | order_items | + tier (string) |
| 27 | payments | без изменений |
| 28 | order_files | без изменений |
| 29 | generation_passes | без изменений |
| 30 | usage_counters | без изменений |
| 31 | drops | + collection_id FK |
| 32 | drop_items | без изменений |
| 33 | edition_assignments | без изменений |
| 34 | style_votes | без изменений |
| 35 | user_tag_affinities | без изменений |
| 36 | audit_logs | без изменений |
| 37 | app_settings | без изменений |
| **38** | **collections** | **NEW** |
| **39** | **tier_modifiers** | **NEW** |
| **40** | **training_batches** | **NEW** |
| **41** | **reference_images** | **NEW** |

**Итого:** 41 таблица (37 из v0.1 + 4 новых).
