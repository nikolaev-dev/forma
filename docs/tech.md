# FORMA — Техническая документация

> Актуальна на: 2026-02-15 | Rails 8.1.2 | Ruby 3.3.1

## Стек

| Компонент | Технология | Версия |
|-----------|-----------|--------|
| Язык | Ruby | 3.3.1 |
| Фреймворк | Ruby on Rails | 8.1.2 |
| БД | PostgreSQL | 16+ |
| Кэш / очереди | Redis | 7+ |
| Фоновые задачи | Sidekiq | latest |
| Asset pipeline | Propshaft | Rails 8+ |
| CSS | Tailwind CSS | 4.1.18 |
| JS | Stimulus + Turbo (Hotwire) | importmap |
| Web-сервер | Puma | 7.2+ |
| Деплой | Kamal (Docker) | опционально |

## Расширения PostgreSQL

- **citext** — регистронезависимые строки (email, slug)
- **pg_trgm** — триграммный поиск (автодополнение тегов)
- **unaccent** — поиск без учёта акцентов

---

## Gems

### Ядро
| Gem | Назначение |
|-----|-----------|
| `rails` | Фреймворк |
| `pg` | PostgreSQL-адаптер |
| `puma` | Web-сервер |
| `propshaft` | Asset pipeline |
| `bootsnap` | Ускорение загрузки |

### Фронтенд (Hotwire)
| Gem | Назначение |
|-----|-----------|
| `turbo-rails` | SPA-навигация без JS |
| `stimulus-rails` | JS-контроллеры |
| `importmap-rails` | ES-модули без бандлера |
| `tailwindcss-rails` | CSS-фреймворк |
| `jbuilder` | JSON API |

### Фоновые задачи
| Gem | Назначение |
|-----|-----------|
| `sidekiq` | Очередь задач |
| `redis` | Брокер для Sidekiq, кэш, rate limiting |

### Аутентификация (OmniAuth)
| Gem | Провайдер |
|-----|----------|
| `omniauth` | Базовый фреймворк |
| `omniauth-rails_csrf_protection` | CSRF-защита |
| `omniauth-google-oauth2` | Google |
| `omniauth-vkontakte` | VK |
| `omniauth-yandex` | Яндекс |

### Хранилище и изображения
| Gem | Назначение |
|-----|-----------|
| `aws-sdk-s3` | S3-compatible storage (Yandex Object Storage) |
| `image_processing` | ActiveStorage variants (resize, crop) |

### PDF и штрихкоды
| Gem | Назначение |
|-----|-----------|
| `prawn` | Генерация PDF |
| `prawn-table` | Таблицы в PDF |
| `barby` | Генерация штрихкодов (Code128) |
| `chunky_png` | PNG для штрихкодов |

### Публичные ID
| Gem | Назначение |
|-----|-----------|
| `hashid-rails` | 6-символьные hashid из id (не хранятся в БД) |

### Утилиты
| Gem | Назначение |
|-----|-----------|
| `csv` | Импорт/экспорт CSV |
| `kamal` | Docker-деплой |
| `thruster` | HTTP-кэширование и сжатие для Puma |

### Разработка и тестирование
| Gem | Назначение |
|-----|-----------|
| `factory_bot_rails` | Фабрики тестовых данных |
| `faker` | Генерация фейковых данных |
| `mocha` | Мокирование (только внешние HTTP) |
| `capybara` | Системные тесты |
| `selenium-webdriver` | Браузерная автоматизация |
| `shoulda-matchers` | Удобные матчеры |
| `rubocop-rails-omakase` | Линтер (Rails Omakase style) |
| `brakeman` | Статический анализ безопасности |
| `bundler-audit` | Аудит уязвимостей в gem'ах |
| `debug` | Дебаггер |
| `web-console` | Веб-консоль в development |

---

## Архитектура БД (32 миграции, 32 таблицы)

### Пользователи и авторизация

```
users
├── id, email (citext), name, phone
├── role: string (user/creator/moderator/admin)
├── status: string (active/blocked/deleted)
├── locale, preferences (jsonb)
└── hashid-rails (публичный ID)

oauth_identities
├── user_id (FK)
├── provider: string (vk/yandex/tbank/alfa/google)
├── uid, tokens (encrypted)
└── unique: [provider, uid]

anonymous_identities
├── anon_token_hash (unique)
└── fingerprint_hash, ip, user_agent
```

### Теги и таксономия

```
tag_categories
├── name, slug (unique), position, is_active
└── has_many :tags

tags
├── tag_category_id (FK)
├── name, slug (unique)
├── visibility: string (public/hidden)
├── kind: string (generic/brand_mood)
├── weight, is_banned
└── trigram-индекс на name

tag_synonyms
├── tag_id (FK), phrase, normalized_phrase
└── unique: [tag_id, normalized_phrase]

tag_relations
├── from_tag_id, to_tag_id (FK)
├── relation_type: string (parent_of/related/conflicts_with/discouraged_with)
└── weight
```

### Стили и каталог

```
styles
├── name, slug (unique)
├── status: string (draft/published/hidden)
├── generation_preset (jsonb), position, popularity_score
├── ActiveStorage: cover_image, gallery_images[]
└── hashid-rails

style_tags
└── style_id + tag_id (unique pair)

catalog_sections
├── name, slug (unique)
├── section_type: string (editorial/popular/new/drop/custom)
└── position, is_active

catalog_items
├── catalog_section_id (FK)
├── item: polymorphic (Style и др.)
└── position, pinned
```

### Дизайны и генерация

```
designs
├── user_id (FK, optional), style_id (FK, optional)
├── source_design_id (FK, self-ref → ремиксы)
├── title, base_prompt, slug
├── visibility: string (private/unlisted/public)
├── moderation_status: string (ok/requires_review/blocked)
├── search_vector (tsvector), view_count, popularity_score
├── ActiveStorage: hero_image, share_image
└── hashid-rails

design_tags
├── design_id + tag_id (FK)
└── source: string (user/system/admin/autotag)

prompts
├── design_id (FK)
└── current_text

prompt_versions
├── prompt_id (FK), text
├── changed_by_user_id (FK, optional)
└── change_reason, diff_summary

generations
├── design_id, user_id, anonymous_identity_id (FK)
├── source: string (create/refine/remix/admin_batch)
├── status: string (created/queued/running/partial/succeeded/failed/canceled)
├── provider, preset_snapshot (jsonb), tags_snapshot (jsonb)
├── error_code, error_message
└── started_at, finished_at

generation_variants
├── generation_id (FK)
├── kind: string (main/mutation_a/mutation_b)
├── status: string (created/queued/running/succeeded/failed)
├── composed_prompt, mutation_summary
├── mutation_tags_added/removed (jsonb)
├── provider_job_id, seed
├── ActiveStorage: preview_image, mockup_image, hires_image
└── unique: [generation_id, kind]

generation_selections
└── generation_id, generation_variant_id, user_id, anonymous_identity_id (FK)
```

### Заказы и оплата

```
orders
├── user_id, anonymous_identity_id (FK, optional)
├── order_number (unique), barcode_value (unique)
├── status: string (draft/awaiting_payment/paid/in_production/shipped/delivered/canceled/refunded)
├── subtotal_cents, shipping_cents, total_cents (integer)
├── currency: "RUB"
├── customer_name, customer_phone, customer_email (citext)
├── shipping_method, shipping_address (jsonb), tracking_number
└── hashid-rails

order_items
├── order_id, design_id, notebook_sku_id, filling_id (FK)
├── quantity, unit_price_cents, total_price_cents (integer)
└── format, settings_snapshot (jsonb)

payments
├── payable: polymorphic (Order | GenerationPass)
├── provider: string (yookassa)
├── provider_payment_id (unique where NOT NULL)
├── status: string (created/pending/succeeded/canceled/failed/refunded)
├── amount_cents (integer), currency: "RUB"
├── idempotence_key, confirmation_url
├── captured_at, raw (jsonb)
└── идемпотентность через provider_payment_id + status

order_files
├── order_id (FK)
├── file_type: string (cover_print_pdf/inner_print_pdf/dna_card_pdf/packing_slip_pdf/preview_pack_zip)
├── status: string (created/rendering/ready/failed)
├── metadata (jsonb)
└── ActiveStorage: file

notebook_skus
├── code (unique): base/pro/elite
├── name, price_cents (integer), currency: "RUB"
└── is_active, specs (jsonb), brand_elements (jsonb)

fillings
├── name, slug (unique)
├── filling_type: string (grid/ruled/dot/blank/planner_weekly/planner_daily/dated)
├── is_active, default_settings (jsonb)
└── ActiveStorage: preview_spread_image
```

### Лимиты и монетизация

```
generation_passes
├── user_id (FK, optional)
├── status: string (active/expired/canceled)
├── starts_at, ends_at
├── price_cents (integer, default 10000), currency: "RUB"
└── has_many :payments (polymorphic)

usage_counters
├── user_id / anonymous_identity_id (one of two, NOT both)
├── period (date), generations_count
└── unique partial indexes: [user_id, period], [anonymous_identity_id, period]
```

### Социальность

```
favorites
├── user_id, design_id (FK)
└── unique: [user_id, design_id]

design_ratings
├── design_id, user_id (FK, optional)
├── score (1-5)
├── source: string (user/admin)
└── unique partial: [design_id, user_id] where source='user'
```

### Админка и система

```
audit_logs
├── actor_user_id (FK)
├── record: polymorphic
├── action (string), before/after (jsonb)
└── ip (string)

app_settings
├── key (unique), value (jsonb)
└── updated_by_user_id (FK, optional)
```

---

## State Machines

### Generation
```
created → queued → running → succeeded
                           → partial (часть вариантов failed)
                           → failed
           created → canceled
```

### Order
```
draft → awaiting_payment → paid → in_production → shipped → delivered
                         → canceled
        awaiting_payment → canceled
                                    paid → refunded
```

### Payment
```
created → pending → succeeded
                  → canceled
                  → failed
         succeeded → refunded
```

### GenerationPass
```
active → expired
       → canceled
```

---

## Сервисы (13 файлов)

### Генерация (`app/services/generations/`)

| Сервис | Назначение |
|--------|-----------|
| `Pipeline` | Оркестратор: Design → Prompt → Generation → 3 Variants → GenerationJob. Проверяет лимиты и rate limit |
| `PromptComposer` | Сборка промпта: user_prompt + style.generation_preset + tags + hidden_tags + POLICY_SUFFIX |
| `TagMutationEngine` | Выбор 1-2 тегов для мутаций через TagRelation (related, peers по категории) |
| `LimitChecker` | Проверка лимитов (гость: 5/день, юзер: 30/день). Учитывает активный GenerationPass |
| `RateLimiter` | Rate limiting через Redis sorted sets (5/мин на юзера, 3/мин на IP) |
| `ProviderInterface` | Абстрактный интерфейс провайдера (create_generation, get_status, fetch_result, cancel) |
| `Providers::TestProvider` | Заглушка провайдера для тестов |

### Заказы (`app/services/orders/`)

| Сервис | Назначение |
|--------|-----------|
| `NumberGenerator` | Формат: FORMA-YYYY-NNNNNN (sequential) |
| `BarcodeGenerator` | Code128 PNG через Barby + ChunkyPNG |

### Оплата (`app/services/payments/`)

| Сервис | Назначение |
|--------|-----------|
| `YookassaClient` | HTTP-обёртка ЮKassa API: create_payment, create_order_payment, get_payment, create_refund. PaymentError для HTTP/сетевых ошибок |
| `WebhookProcessor` | Идемпотентная обработка webhook'ов: проверка provider_payment_id + status, обновление Payment → Order/GenerationPass |

### Теги (`app/services/tags/`)

| Сервис | Назначение |
|--------|-----------|
| `CsvImporter` | Массовый импорт тегов из CSV |
| `Merger` | Мерджинг дублей тегов |

---

## Фоновые задачи (Sidekiq)

| Job | Очередь | Назначение |
|-----|---------|-----------|
| `GenerationJob` | `:generation` | Запуск генерации: вызов провайдера, polling результатов, сохранение в ActiveStorage. retry_on с polynomial backoff |
| `OrderFileGenerationJob` | `:default` | Создание записей OrderFile (cover_print_pdf, inner_print_pdf, dna_card_pdf). Реальная PDF-генерация — заглушка |
| `PopularityScoreJob` | `:default` | Пересчёт popularity_score для публичных дизайнов (рейтинги, избранное, покупки, ремиксы) |

**ApplicationJob** — базовый класс:
- `retry_on ActiveRecord::Deadlocked` (wait: 5s, attempts: 3)
- `discard_on ActiveJob::DeserializationError`

---

## Контроллеры (21 файл)

### Основные

| Контроллер | Экраны | Назначение |
|-----------|--------|-----------|
| `CatalogController` | S1 | Витрина: editorial, popular styles/designs, секции |
| `CreationsController` | S3-S5 | Создание: промпт → генерация → прогресс → результат |
| `DesignsController` | S7 | Публичная страница дизайна: show, remix, toggle_favorite, rate |
| `OrdersController` | S8-S12 | Заказ: filling → sku → checkout → pay → confirmed |
| `FavoritesController` | S14 | Избранное |
| `GenerationPassesController` | L1 | Безлимит: лимит исчерпан → покупка → подтверждение |
| `SessionsController` | — | OmniAuth: login, logout, failure |

### Админка (`/admin`)

| Контроллер | Назначение |
|-----------|-----------|
| `Admin::DashboardController` | Главная админки |
| `Admin::TagsController` | CRUD тегов, CSV-импорт, мердж |
| `Admin::TagSynonymsController` | Синонимы тегов (вложенный ресурс) |
| `Admin::StylesController` | CRUD стилей, publish/hide |
| `Admin::OrdersController` | Заказы: список, карточка, смена статуса, CSV-экспорт |
| `Admin::SettingsController` | AppSettings (лимиты, цены) |
| `Admin::AuditLogsController` | Журнал аудита |

### API (`/api`)

| Контроллер | Endpoint | Назначение |
|-----------|----------|-----------|
| `Api::CatalogController` | `GET /api/catalog/styles`, `/sections` | JSON-каталог |
| `Api::TagsController` | `GET /api/tags/search` | Поиск тегов (автодополнение) |
| `Api::GenerationsController` | `GET /api/generations/:id/status` | Статус генерации (polling) |

### Webhooks

| Контроллер | Endpoint | Назначение |
|-----------|----------|-----------|
| `Payments::WebhooksController` | `POST /payments/yookassa/webhook` | ЮKassa webhook (skip CSRF, rescue → log, всегда 200) |

---

## Stimulus-контроллеры (JS)

| Контроллер | Назначение |
|-----------|-----------|
| `generation_progress` | Polling статуса генерации, 3-шаговый индикатор, таймаут 3 мин |
| `result_carousel` | Карусель 3 вариантов на экране результата |
| `tag_selector` | Мультивыбор тегов с автодополнением через API |
| `creation_form` | Валидация формы создания |
| `toast` | Toast-уведомления |

---

## Image Variants (ActiveStorage)

| Модель | Метод | Размер | Использование |
|--------|-------|--------|--------------|
| `GenerationVariant` | `preview_thumb` | 300x400 | Каталог, избранное, ремиксы |
| `GenerationVariant` | `preview_medium` | 600x800 | Карусель результата, страница дизайна |
| `Style` | `cover_thumb` | 300x400 | Карточки стилей в каталоге |

---

## Обработка ошибок

| Слой | Механизм |
|------|---------|
| `ApplicationController` | `rescue_from ActiveRecord::RecordNotFound` → 404 (HTML/JSON) |
| `OrdersController#pay` | `rescue Payments::YookassaClient::PaymentError` → flash + redirect |
| `GenerationPassesController#create` | `rescue PaymentError` → flash + redirect |
| `CreationsController#create` | `rescue LimitExceeded` → redirect L1; `rescue RateLimited` → flash |
| `WebhooksController#yookassa` | `rescue => e` → log + head :ok (всегда 200 для ЮKassa) |
| `YookassaClient` | `PaymentError` для HTTP 4xx/5xx, таймаутов, connection refused |
| `WebhookProcessor` | Структурированное логирование всех переходов |

---

## CI/CD

### GitHub Actions (`.github/workflows/ci.yml`)

| Job | Что делает |
|-----|-----------|
| `scan_ruby` | Brakeman (статический анализ безопасности) + bundler-audit (уязвимости gem'ов) |
| `scan_js` | importmap audit (JS-зависимости) |
| `lint` | RuboCop (rails-omakase) с кэшированием |
| `test` | `bin/rails test` против PostgreSQL |
| `system-test` | Системные тесты (Capybara + Selenium) |

### Dependabot
- bundler: еженедельно, до 10 PR
- github-actions: еженедельно, до 10 PR

---

## Тестирование

| Категория | Файлов | Описание |
|-----------|--------|----------|
| Models | 30 | Валидации, enum string, state machines, scopes |
| Controllers | 25 | Интеграционные тесты всех экранов и API |
| Services | 13 | Pipeline, PromptComposer, LimitChecker, YookassaClient и др. |
| Jobs | 3 | GenerationJob, OrderFileGenerationJob, PopularityScoreJob |
| Factories | 29 | FactoryBot с traits |
| **Итого** | **459 тестов, 927 assertions, 0 failures** | |

### Принципы тестирования
- **TDD** — тесты пишутся первыми
- **Минимум моков** — мокаются только внешние HTTP (ЮKassa API)
- **Реальные записи** — БД, модели, сервисы работают без моков
- **Параллельные тесты** — `parallelize(workers: :number_of_processors)`

---

## Конвенции

| Правило | Пример |
|---------|--------|
| Enum — только string | `enum :status, { draft: "draft", published: "published" }` |
| Деньги — integer _cents | `price_cents: 319900` (= 3199.00 RUB) |
| Публичные ID — hashid | `design.hashid` → `"k5dm8p"`, не хранится в БД |
| Публичные URL — slug | `/designs/my-cool-design` (fallback на hashid) |
| Валюта | Всегда `"RUB"`, колонка `currency` |

---

## Ключевые конфигурации

### HashID (`config/initializers/hashid.rb`)
- Salt: из credentials или `"forma-hashid-salt"`
- min_length: 6
- Алфавит: lowercase + цифры

### Sidekiq (`config/initializers/sidekiq.rb`)
- Redis URL: `ENV["REDIS_URL"]` или `redis://localhost:6379/0`

### OmniAuth (`config/initializers/omniauth.rb`)
- Провайдеры: VK, Yandex, Google (ключи из credentials)
- `allowed_request_methods: [:post]`

### БД (`config/database.yml`)
- Development: `forma_development`
- Test: `forma_test`
- Production: `forma_production`

---

## Метрики кода

| Категория | Файлов | Строк |
|-----------|--------|-------|
| Модели | 31 | ~740 |
| Сервисы | 13 | ~850 |
| Контроллеры | 21 | ~960 |
| Jobs | 3 | ~155 |
| JS-контроллеры | 7 | ~200 |
| Тесты + фабрики | 100 | ~4360 |
| **Итого бэкенд** | **68** | **~2900** |
