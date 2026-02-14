# FORMA — Instructions for Claude

## Project

FORMA — сервис генерации дизайна обложек блокнотов. Пользователь выбирает стиль, задает промпт/теги, получает 3 превью (основное + 2 мутации), докручивает, заказывает и оплачивает. Бренд = "редакция вкуса", не "кастом-печать".

## Architecture Location

```
docs/v0.1/              — текущая версия спецификации (7 файлов)
docs/PLAN.md            — пошаговый план реализации (этапы 0-9)
docs/CHANGELOG.md       — история изменений документации
manual.md               — сырой исходник (НЕ источник истины — используй docs/)
```

## How to Work With Documentation

### Rule 1: Never load all docs at once

Документация = 7 файлов, ~2500 строк. Загрузка всех убивает контекст. Работай по принципу **minimum context**:

1. Начни с этого CLAUDE.md — тут ключевые решения и конвенции
2. Открой ТОЛЬКО тот файл, который нужен для текущей задачи (см. таблицу ниже)
3. `06-storage.md` — самый большой файл (~600 строк). Читай конкретную таблицу, не весь файл

### Rule 2: Task-to-file mapping

| Если работаешь над...             | Читай файл                |
|-----------------------------------|---------------------------|
| Стек, роли, бренд, термины       | `01-overview.md`          |
| UX-флоу, экраны S0-S17, переходы | `02-user-stories.md`      |
| Каталог, поиск, ремиксы, шаринг  | `03-public.md`            |
| Админка: теги, стили, заказы      | `04-admin.md`             |
| Генерация, мутации, провайдеры    | `05-generation.md`        |
| Схема БД, таблицы, индексы       | `06-storage.md`           |
| ЮKassa, штрихкоды, лимиты        | `07-orders-payments.md`   |
| Что делать следующим             | `PLAN.md`                 |

### Rule 3: PLAN.md is the task list

`docs/PLAN.md` содержит 10 этапов с чеклистом. При начале работы:
1. Открой `PLAN.md`
2. Найди текущий этап (первый с незавершёнными `[ ]`)
3. Возьми следующий пункт
4. Открой соответствующий файл docs/ для деталей
5. Реализуй
6. Отметь `[x]` в PLAN.md

### Rule 4: Dependency order between docs

```
01 (overview) — читай первым, если нужен контекст
06 (storage)  — читай перед созданием миграций/моделей
05 (generation) + 06 (storage) — для пайплайна генерации
07 (orders) + 06 (storage) — для заказов и оплаты
02 (user-stories) — для UI/фронтенда
03 (public) + 04 (admin) — для конкретных фич
```

При реализации: `06-storage.md` нужен почти всегда — но читай только нужную таблицу.

### Rule 5: manual.md is dead

`manual.md` — сырой исходник, из которого создана документация. **Никогда не используй его как источник истины.** Все решения зафиксированы в `docs/v0.1/`. Если есть расхождение — `docs/` побеждает.

## Key Technical Decisions

Запомни — не нужно каждый раз перечитывать:

- **Backend:** Ruby on Rails 7+
- **DB:** PostgreSQL (extensions: citext, pg_trgm, unaccent)
- **Очереди:** Sidekiq + Redis
- **Хранилище файлов:** ActiveStorage + S3-compatible
- **Оплата:** ЮKassa (webhooks, идемпотентные)
- **Auth:** OmniAuth (VK, Яндекс, T-Bank, Альфа, Gmail)
- **Генерация:** абстракция провайдеров (сменяемый интерфейс)
- **Штрихкод:** Code128, gem `barby`
- **Публичные ID:** HashID 6 символов, gem `hashid-rails`

### Ключевые сущности (не перечитывай 06-storage каждый раз)

- **Design** — центральная сущность (дизайн блокнота)
- **Generation** → 3x **GenerationVariant** (main + mutation_a + mutation_b)
- **Tag** (public/hidden) + **TagCategory** + **TagRelation** (совместимость)
- **Style** — карточка каталога с пресетом генерации
- **Order** → **OrderItem** + **Payment** (ЮKassa) + **OrderFile** (PDF для печати)
- **NotebookSku** — Base (2599 ₽) / Pro (3199 ₽) / Elite (8999 ₽)
- **Filling** — внутренний блок (клетка/линейка/точки/пустые)
- **GenerationPass** — безлимит за 100 ₽ на 24 часа

### State machines

```
Generation:  created → queued → running → succeeded | partial | failed | canceled
Order:       draft → awaiting_payment → paid → in_production → shipped → delivered
Payment:     created → pending → succeeded | canceled | failed → refunded
```

### Архитектура генерации (пайплайн)

```
"Сгенерировать" нажата
  → Generation (status: created)
  → 3x GenerationVariant (main, mutation_a, mutation_b)
  → PromptComposer: текст + стиль + теги + скрытые теги + policy
  → TagMutationEngine: выбор 1-2 тегов для мутаций
  → Provider.create_generation() — асинхронно через Sidekiq
  → Результаты → ActiveStorage (S3)
  → Пост-обработка: мокап блокнота, thumbnail
```

## Hard Conventions

Нарушение любого из этих правил — баг. Проверяй перед каждым написанием кода.

### 1. Enum — ТОЛЬКО строчные (string)

```ruby
# ПРАВИЛЬНО
enum :status, { draft: "draft", published: "published", hidden: "hidden" }

# НЕПРАВИЛЬНО — НИКОГДА integer enum
enum :status, { draft: 0, published: 1, hidden: 2 }
```

В миграциях: `status: string, null: false, default: "draft"`, не integer.

### 2. Деньги — integer в копейках

```ruby
# ПРАВИЛЬНО
price_cents: 319900  # 3199.00 ₽
currency: "RUB"

# НЕПРАВИЛЬНО
price: 3199.00  # никогда float/decimal для денег
```

### 3. Публичные ID — HashID (6 символов)

Gem `hashid-rails`. Вычисляется из `id`, **не хранится в БД**.

```ruby
class Design < ApplicationRecord
  include Hashid::Rails
end

design.hashid        # => "k5dm8p"
Design.find(hashid)  # => #<Design id: 42>
```

**Не создавай колонку `public_id` или `uuid`.** Используй hashid.

### 4. Публичные URL — slug

Сущности с человекочитаемыми URL: styles, tags, tag_categories, designs, drops, fillings, catalog_sections.

Маршрутизация: **slug (приоритет) > hashid (fallback)**.

## Common Mistakes to Avoid

1. **Не используй integer enum.** Если видишь `status: 0` или `role: 10` — это баг. Только string.
2. **Не создавай колонку `public_id` / `uuid`.** Публичные ID = hashid из `id`, вычисляются на лету.
3. **Не выдумывай поля/таблицы.** Бери из `06-storage.md`. Если поля нет — спроси, а не добавляй.
4. **Не делай генерации синхронными.** Всё через Sidekiq. UI получает статусы через polling/WebSocket.
5. **Не хардкодь провайдера генерации.** Всегда через абстракцию (интерфейс Provider).
6. **Не пропускай consent/moderation check.** Brand-теги = mood only, без логотипов. Policy flag в промптах.
7. **Не забывай идемпотентность webhook ЮKassa.** Проверка `provider_payment_id` + `status` перед обновлением.
8. **Не используй `manual.md` как источник истины.** Только `docs/v0.1/`.
9. **Не создавай миграцию с `float`/`decimal` для денег.** Только `integer` + `_cents` суффикс.

## Code Organization Conventions

При создании кода (когда дойдем до реализации):

```
forma/
  docs/                          — спецификация (read-only при разработке)
  app/
    models/                      — AR модели (Design, Tag, Generation, Order...)
    services/
      generation/
        prompt_composer.rb       — сборка финального промпта
        tag_mutation_engine.rb   — выбор тегов для мутаций
        provider_interface.rb    — абстракция провайдера
        providers/               — конкретные провайдеры (stable_diffusion, dall_e...)
      orders/
        barcode_generator.rb     — Code128 штрихкоды
        file_generator.rb        — PDF для печати (cover, inner, dna_card)
      payments/
        yookassa_client.rb       — API ЮKassa
        webhook_processor.rb     — обработка webhooks
      tags/
        csv_importer.rb          — массовый импорт
        merger.rb                — мердж дублей
      search/
        query_builder.rb         — full-text + faceted search
    jobs/                        — Sidekiq jobs (GenerationJob, OrderFileJob...)
    controllers/
      api/                       — JSON API (если отдельный фронт)
      admin/                     — админка
    views/                       — если Hotwire/Turbo
  config/
    initializers/
      hashid.rb                  — hashid-rails config (salt, min_length: 6)
      sidekiq.rb                 — Sidekiq + Redis
      yookassa.rb                — ЮKassa credentials
  db/
    migrate/                     — миграции (по порядку из 06-storage.md)
```

## Working With the User

- Общение на русском
- Технические термины допустимы на английском (Sidekiq, ActiveStorage, webhook, slug, hashid...)
- Ценит структурированность, чеклисты, версионность документации
- Жестко следит за конвенциями (enum string, деньги _cents, hashid) — если нарушил, поправь немедленно
- `docs/` — источник истины. При изменении архитектуры — обнови соответствующий файл + `CHANGELOG.md`
- Не предлагай shortcuts которые нарушают конвенции

## Current State

Проект на стадии документации. Rails-приложение еще не создано. Следующий шаг — **Этап 0** из `docs/PLAN.md` (инфраструктура и каркас).
