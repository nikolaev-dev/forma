# 04. Админка — FORMA

> Версия: v0.2 | Дата: 2026-02-15

Админке уделяется столько же внимания, сколько пользовательской части — иначе нельзя "эволюционировать самому".

v0.2 добавляет Training Pipeline, коллекции, tier-модификаторы и расширяет режим куратора.

---

## 1. Разделы админки

| Раздел | Описание |
|--------|----------|
| Теги | CRUD, импорт, синонимы, совместимость |
| Стили | CRUD, привязка тегов, пресеты |
| **Коллекции** | CRUD, привязка дизайнов, stock tracking (NEW v0.2) |
| Витрины / Подборки | Редакция, популярное, категории |
| **Training Pipeline** | Загрузка → AI-анализ → курирование → 3-tier генерация → публикация (NEW v0.2) |
| Курация (Режим куратора) | Batch-генерации, оценки 1-5, tier-генерация, публикация (UPDATED v0.2) |
| **Tier-модификаторы** | CRUD промпт-модификаторов для Core/Signature/Lux (NEW v0.2) |
| Заказы | Статусы, файлы, экспорт |
| Дропы / Edition | Лимитированные коллекции, привязка к Collection (UPDATED v0.2) |
| Лимиты / Тарифы | Цены, лимиты, промокоды |
| Настройки | App settings, key-value |
| Аудит | Лог действий админов |

---

## 2. Управление тегами

### 2.1. CRUD тегов

| Поле | Тип | Описание |
|------|-----|----------|
| name | string | Название тега |
| slug | string | URL-slug (auto-generate) |
| tag_category_id | FK | Категория |
| visibility | string enum | `"public"` / `"hidden"` |
| kind | string enum | `"generic"` / `"brand_mood"` |
| weight | decimal | Вес для рекомендаций/мутаций |
| is_banned | boolean | Запрещен |
| banned_reason | string | Причина бана |

### 2.2. Массовый импорт CSV

- Формат: `name,category,visibility,kind`
- Валидация дублей
- Автогенерация slug
- Лог импорта (сколько создано, обновлено, ошибок)

### 2.3. Синонимы и транслитерации

- У каждого тега — список синонимов (tag_synonyms)
- Нормализованная форма для поиска
- Примеры: "кофе" = "coffee", "золото" = "gold"

### 2.4. Правила совместимости (tag_relations)

| Тип связи (string enum) | Описание |
|--------------------------|----------|
| `"parent_of"` | Иерархия |
| `"related"` | Связанные |
| `"conflicts_with"` | Нельзя вместе |
| `"discouraged_with"` | Нежелательно вместе |

### 2.5. Черный список

- Теги с `is_banned: true`
- Невидимы пользователю
- Блокируются при вводе промпта

### 2.6. Мердж дублей

- Выбор "основного" тега
- Перенос всех связей на основной
- Удаление дубля

---

## 3. Управление стилями

### 3.1. Карточка стиля

| Поле | Описание |
|------|----------|
| Название | Редакционное название |
| Описание | Короткое |
| 1-5 изображений | Примеры (ActiveStorage) |
| Набор тегов | Включая скрытые |
| Пресет генерации | JSON: параметры провайдера/модели/пост-обработки |
| Статус | `"draft"` / `"published"` / `"hidden"` |
| Позиция | Порядок в каталоге |
| Метрики | Просмотры / лайки / заказы (read-only) |

### 3.2. Статусы стиля (string enum)

```
"draft"      -> "published"  (публикация)
"published"  -> "hidden"     (скрытие)
"hidden"     -> "published"  (повторная публикация)
"draft"      -> (удаление)
```

---

## 4. Витрины / Подборки

### 4.1. Типы витрин (string enum)

| Тип | Описание |
|-----|----------|
| `"editorial"` | Редакция FORMA — ручной отбор |
| `"popular"` | Популярное — автоматически по метрикам |
| `"new"` | Новые — хронологически |
| `"drop"` | Дроп — привязка к Drop |
| `"collection"` | Коллекция — привязка к Collection (NEW v0.2) |
| `"custom"` | Произвольная подборка |

### 4.2. Функции

- Ручная фиксация карточек в топ (pinned)
- Расписание публикаций (опционально)
- Правила автонаполнения (JSON rules, например `rating>=4`)

---

## 5. Training Pipeline (NEW v0.2)

Полный цикл превращения референсных фотографий в каталожные дизайны: загрузка фото реальных блокнотов, AI-анализ, ручное курирование, генерация в 3 уровнях исполнения, публикация в каталог.

### 5.1. Общая схема

```
ЗАГРУЗКА → AI-АНАЛИЗ → КУРИРОВАНИЕ → 3-TIER ГЕНЕРАЦИЯ → ПУБЛИКАЦИЯ
   ↓            ↓             ↓                ↓                ↓
TrainingBatch  Sidekiq     Куратор      Core/Signature/Lux   Design
ReferenceImage Claude/GPT  правит         approve/reject    в каталоге
(uploaded)    (analyzed)   (curated)      (generated)       (published)
```

### 5.2. Загрузка референсов

#### UI

- Drag-n-drop зона для загрузки фотографий (одиночных или пачками)
- Загрузка ZIP-архива (автоматическая распаковка)
- При загрузке создаются:
  - `TrainingBatch` (status: `"uploaded"`, name: задается куратором или auto)
  - N x `ReferenceImage` (status: `"uploaded"`, привязка к batch)

#### Grid-интерфейс

| Элемент | Описание |
|---------|----------|
| Карточка | Thumbnail референса, статус, имя файла |
| Фильтры | По статусу: uploaded / analyzing / analyzed / curated / generated / published / rejected |
| Сортировка | По дате, по статусу, по batch |
| Batch-панель | Название, дата, количество, прогресс (N/M analyzed) |
| Выбор | Чекбоксы для bulk-действий |

#### Валидация при загрузке

- Форматы: JPEG, PNG, WebP
- Макс. размер: 20 MB / файл
- ZIP: макс. 500 MB, макс. 200 файлов
- Дедупликация по content hash (предупреждение, не блокировка)

### 5.3. AI-анализ

#### Запуск

- Кнопка "Анализировать" на уровне batch или выбранных referenceImage
- Каждое изображение отправляется на анализ **двум провайдерам** (A/B тест):
  - Claude Vision
  - GPT-4V
- Обработка через Sidekiq (`ReferenceImageAnalysisJob`)
- Статус: `"uploaded"` → `"analyzing"` → `"analyzed"`

#### Извлекаемые данные

Результат анализа каждого провайдера сохраняется в отдельном jsonb-поле:

| Поле в jsonb | Тип | Описание |
|-------------|-----|----------|
| description | string | Описание: что изображено на обложке |
| base_prompt | string | Промпт для воспроизведения дизайна |
| suggested_tags | array[string] | Теги из существующей таксономии |
| mood | string | Настроение (serene, bold, playful...) |
| dominant_colors | array[string] | Доминантные цвета (hex) |
| visual_style | string | Визуальный стиль (watercolor, minimalist, geometric...) |
| complexity | string | Сложность (low / medium / high) |
| suggested_collection | string | Предложение коллекции |

**Хранение:**

```
reference_images.ai_analysis_claude  (jsonb)  ← результат Claude Vision
reference_images.ai_analysis_openai  (jsonb)  ← результат GPT-4V
```

#### Фоновая обработка

- Sidekiq job на каждый ReferenceImage x провайдер
- Rate limiting: макс. 10 параллельных запросов к каждому провайдеру
- Retry: 3 попытки с exponential backoff
- При ошибке одного провайдера — второй продолжает работать
- Batch-прогресс: обновление `training_batches.images_count` vs analyzed count

#### Идемпотентность

- Повторный запуск AI-анализа **не затирает курированные данные**
- Если `status >= curated` — анализ блокируется (нужно явное "переанализировать")
- AI-поля (ai_analysis_claude, ai_analysis_openai) перезаписываются при re-analyze

### 5.4. Курирование

#### Layout

Двухколоночный интерфейс:

```
┌─────────────────────────────┬─────────────────────────────┐
│                             │  Provider: [Claude ▼] [GPT] │
│    ОРИГИНАЛЬНОЕ ФОТО        │                             │
│    (референс)               │  Промпт: _________________ │
│                             │  __________________________ │
│                             │  __________________________ │
│                             │                             │
│                             │  Теги: [japan][autumn][x]   │
│                             │        [+ добавить тег]     │
│                             │                             │
│                             │  Коллекция: [Восточная ▼]   │
│                             │  [+ создать новую]          │
│                             │                             │
│                             │  Mood: [serene]             │
│                             │  Colors: ■ ■ ■              │
│                             │  Style: watercolor          │
│                             │                             │
│                             │  Заметки куратора:          │
│                             │  __________________________ │
│                             │                             │
│                             │  [Сохранить] [Пропустить]   │
└─────────────────────────────┴─────────────────────────────┘
```

#### Выбор провайдера

- Переключатель Claude / GPT-4V вверху правой панели
- При переключении — подгружаются данные соответствующего анализа
- Куратор выбирает, чей промпт лучше → `selected_provider` (string: `"claude"` / `"openai"`)
- Выбранный промпт копируется в `curated_prompt`
- Куратор может редактировать промпт inline после выбора

#### Редактирование промпта

- Textarea с `curated_prompt`
- Если куратор не выбрал провайдера — промпт пустой, нужно выбрать или ввести вручную
- Подсветка diff между оригиналом (AI) и правками куратора (опционально)

#### Теги

- Chip-компоненты с autocomplete
- Поиск по существующей таксономии (триграммы + синонимы)
- Можно добавить теги, которых нет в AI-предложениях
- Можно удалить предложенные AI
- Итоговые теги сохраняются в привязку reference_image ↔ tags

#### Коллекция

- Dropdown с существующими коллекциями
- Кнопка "Создать новую" → inline-форма (name, slug, type)
- Привязка: `reference_images.collection_id`

#### Bulk-действия

| Действие | Описание |
|----------|----------|
| Применить коллекцию | Выбранным → назначить одну коллекцию |
| Применить теги | Выбранным → добавить набор тегов |
| Пометить rejected | Выбранные → status: rejected |
| Запустить генерацию | Выбранные curated → 3-tier генерация |

#### Статус

- После сохранения: `reference_images.status` → `"curated"`
- Обязательные поля для перехода в curated:
  - `curated_prompt` (не пустой)
  - `selected_provider` (выбран)

### 5.5. 3-Tier генерация

#### Запуск

- Из curated-промпта генерируются **3 изображения** (Core / Signature / Lux)
- Каждое изображение = отдельный prompt, собранный из:

```
{SCENE_SETUP} + {curated_prompt} + {TIER_MODIFIER} + {IDENTITY_ELEMENTS} + {NEGATIVE_PROMPT}
```

- Tier-модификаторы берутся из таблицы `tier_modifiers` (см. раздел 10)
- Генерация запускается через Sidekiq (`TierGenerationJob`)
- Создается `Generation` с 3 x `GenerationVariant` (tier: core / signature / lux)
- Статус: `"curated"` → `"generated"`

#### Layout

Двухколоночный интерфейс:

```
┌─────────────────────────────┬─────────────────────────────┐
│                             │  ┌─────────┐ ┌───────────┐  │
│    ОРИГИНАЛЬНОЕ ФОТО        │  │  CORE   │ │ SIGNATURE │  │
│    (референс)               │  │         │ │           │  │
│                             │  │ [✓][✗][↻]│ │ [✓][✗][↻] │  │
│                             │  └─────────┘ └───────────┘  │
│                             │  ┌───────────┐              │
│    curated_prompt:          │  │    LUX    │              │
│    "Japanese zen garden..." │  │           │              │
│                             │  │ [✓][✗][↻] │              │
│                             │  └───────────┘              │
│                             │                             │
│                             │  Статус: 2/3 approved       │
│                             │  [Опубликовать]             │
└─────────────────────────────┴─────────────────────────────┘
```

#### Действия по каждому tier-варианту

| Действие | Описание |
|----------|----------|
| Approve (✓) | Одобрить вариант для публикации |
| Reject (✗) | Отклонить (не публиковать этот tier) |
| Regenerate (↻) | Перегенерировать только этот tier (новый seed, тот же промпт) |

#### Правила

- Минимум **1 approved tier** для публикации (обычно все 3)
- Перегенерация создает новый GenerationVariant, старый помечается как rejected
- Куратор может отредактировать промпт перед перегенерацией конкретного tier

### 5.6. Публикация

#### Действие

Кнопка "Опубликовать" создает:

1. **Design** в каталоге:
   - visibility: `"public"`
   - Привязка к тегам из curated-набора
   - Привязка к коллекции (если назначена)
   - Привязка к стилю (если определен)
   - Slug: auto-generate из curated_prompt или задается вручную

2. **Связь с источником:**
   - `reference_images.design_id` = ID созданного Design
   - `reference_images.status` = `"published"`

3. **Tier-варианты:**
   - Approved GenerationVariant привязаны к Design
   - Каждый вариант содержит tier (core / signature / lux) + изображение

#### Bulk-публикация

- "Опубликовать все одобренные" — массовое создание Design для всех reference_images со status `"generated"` и >= 1 approved tier

### 5.7. Dashboard Training Pipeline

Общая сводка на главной странице раздела:

| Метрика | Описание |
|---------|----------|
| Всего референсов | Общее количество ReferenceImage |
| По статусам | uploaded / analyzing / analyzed / curated / generated / published / rejected |
| Батчей | Количество TrainingBatch, последний батч |
| AI-анализ | Очередь (pending jobs), средняя длительность, ошибки |
| Провайдер-статистика | Claude vs GPT-4V: сколько раз выбран куратором |
| Коллекции | Количество, заполненность |
| Готово к публикации | generated + approved, ожидают "Опубликовать" |

---

## 6. Управление коллекциями (NEW v0.2)

### 6.1. CRUD коллекций

| Поле | Тип | Описание |
|------|-----|----------|
| name | string | Название коллекции |
| slug | string | URL-slug (unique, auto-generate) |
| description | text | Описание для каталога |
| collection_type | string enum | `"regular"` / `"limited"` |
| edition_size | integer | Размер тиража (только для limited, NULL для regular) |
| cover_image | ActiveStorage | Обложка коллекции |
| is_active | boolean | Активна / скрыта |
| position | integer | Порядок в каталоге |

### 6.2. Привязка дизайнов

- Drag-n-drop сортировка дизайнов внутри коллекции
- Position ordering (acts_as_list или ручное)
- Один дизайн может быть в нескольких коллекциях (many-to-many через `collection_designs`)
- При удалении коллекции — дизайны остаются, привязки удаляются

### 6.3. Stock tracking (для limited)

| Метрика | Описание |
|---------|----------|
| edition_size | Размер тиража |
| stock_remaining | Остаток (автоматически уменьшается при заказе) |
| sold_count | Продано (edition_size - stock_remaining) |
| Нумерация | "001/030" ... "030/030" — назначается при покупке |

- Визуальный прогресс-бар: sold / total
- Предупреждение при stock_remaining <= 5
- Блокировка заказа при stock_remaining = 0

### 6.4. Статусы коллекции

```
"draft"      -> "active"     (публикация)
"active"     -> "hidden"     (скрытие)
"hidden"     -> "active"     (повторная публикация)
"active"     -> "sold_out"   (автоматически при stock_remaining = 0, только limited)
```

---

## 7. Режим "Куратор" (UPDATED v0.2)

### 7.1. Назначение

Интерфейс, где админ наполняет каталог качественными дизайнами. В v0.2 расширен поддержкой tier-оси и интеграцией с Training Pipeline.

### 7.2. Функции

| Действие | Описание |
|----------|----------|
| Batch-генерация | Запуск генерации пачками по стилю/набору тегов |
| **3-Tier batch-генерация** | Запуск генерации Core/Signature/Lux пачками (NEW v0.2) |
| Просмотр результатов | Лента сгенерированных вариантов |
| Оценка 1-5 | Быстрая оценка качества |
| "Доп. генерация" | Перегенерировать |
| "Добавь стиль" | Создать новый стиль из удачного результата |
| "Отправить в каталог" | Опубликовать дизайн |
| "Пометить теги" | Быстрый редактор тегов (включая скрытые) |
| **"Назначить коллекцию"** | Привязка к коллекции (NEW v0.2) |
| **"Генерировать 3 tiers"** | Из текущего промпта → Core/Signature/Lux (NEW v0.2) |
| **"Опубликовать все одобренные"** | Массовая публикация approved вариантов (NEW v0.2) |

### 7.3. Поток работы (обновленный)

#### Классический поток (как в v0.1)

1. Админ выбирает стиль или набор тегов
2. Запускает batch (N генераций)
3. Просматривает результаты (лента карточек)
4. Ставит оценку 1-5
5. Лучшие (4-5) -> "Отправить в каталог"
6. Результат с оценкой >= 4 -> витрина "Редакция FORMA"

#### Tier-поток (NEW v0.2)

1. Админ выбирает дизайн (из batch или из Training Pipeline)
2. Нажимает "Генерировать 3 tiers"
3. Система собирает 3 промпта (base + tier_modifier для каждого уровня)
4. Генерируются 3 варианта: Core / Signature / Lux
5. Куратор оценивает каждый: approve / reject / regenerate
6. Назначает коллекцию
7. "Опубликовать" -> Design с 3 tier-вариантами в каталоге

### 7.4. Dashboard куратора (NEW v0.2)

| Метрика | Описание |
|---------|----------|
| Training Pipeline | Сводка по статусам (ссылка на раздел 5.7) |
| Batch-прогресс | Текущие batch-генерации, очередь |
| Ожидают оценки | Количество непросмотренных вариантов |
| Готово к публикации | approved-варианты, ожидающие "Опубликовать" |
| Статистика | Опубликовано сегодня / за неделю / всего |

---

## 8. Управление заказами

### 8.1. Список заказов

**Фильтры:**
- Статус (draft, paid, in_production, shipped, delivered, canceled, refunded)
- Дата (от-до)
- Тариф (Core/Signature/Lux)
- Коллекция (NEW v0.2)
- Дроп / обычный
- Способ доставки
- Оплачен / не оплачен
- Поиск по номеру/почте/телефону

**Колонки таблицы:**
- Номер заказа
- Клиент
- Сумма
- Tier (Core/Signature/Lux)
- Статус
- Дата
- Кнопка "Открыть"

### 8.2. Карточка заказа

| Блок | Содержимое |
|------|-----------|
| Клиент | Имя, телефон, email |
| Состав | Дизайн (ссылка), tier, комплектация, наполнение, формат |
| Коллекция | Название коллекции (если есть), edition number (если limited) |
| Штрихкод | Визуально + значение (Code128) |
| Статусы | Timeline: paid -> in_production -> shipped -> delivered |
| Файлы производства | Обложка PDF, внутренний блок PDF, превью, DNA Card |
| Платежи | payment_id, статус, суммы, возвраты |

### 8.3. Смена статуса заказа

```
"draft" -> "awaiting_payment" -> "paid" -> "in_production" -> "shipped" -> "delivered"
"paid" -> "canceled"
"paid" -> "refunded"
```

Кнопки: "В производство", "Отправлен" (+ трек-номер), "Доставлен"

### 8.4. Экспорт

| Формат | Описание |
|--------|----------|
| CSV | Список заказов с фильтрами |
| PDF Лист комплектации | Для производства |
| PDF Наклейки штрихкодов | Пакетная печать |

### 8.5. Возвраты / Отмена

- Отмена до производства — автовозврат через YooKassa
- Отмена после — ручное решение
- Журнал действий (audit_logs)

---

## 9. Управление DNA Card и манифестом

| Настройка | Описание |
|-----------|----------|
| Шаблон манифеста | Текст по локалям |
| Формат DNA Card | Какие поля печатать, где QR, где ID |
| Tier-специфика | Core: простая карточка, Signature: + персонализация, Lux/Limited: номерной паспорт |

---

## 10. Tier-модификаторы (NEW v0.2)

### 10.1. Назначение

Tier-модификаторы определяют, как базовый промпт дизайна трансформируется для каждого уровня исполнения (Core / Signature / Lux). Хранятся в таблице `tier_modifiers`.

### 10.2. CRUD

| Поле | Тип | Описание |
|------|-----|----------|
| tier | string enum | `"core"` / `"signature"` / `"lux"` (unique) |
| prompt_modifier | text | Текст-модификатор, добавляемый к базовому промпту |
| identity_elements | text | Описание brand identity элементов для данного tier |
| negative_prompt | text | Общий negative prompt |
| settings | jsonb | Параметры генерации: aspect_ratio, lens, style_notes |

### 10.3. Seed-данные (defaults)

При создании системы — 3 записи с начальными значениями:

**Core:**
```
prompt_modifier: "Coated paper wrap cover (NOT leather), matte lamination, flat
  printed wave (no UV, no embossing), simple elastic band, two plain ribbon
  bookmarks, no metal hardware, no badge, clean minimal product"

identity_elements: "chamfered 45-degree top-right corner, two plain ribbon
  bookmarks, simple printed DNA card in pocket"

negative_prompt: "cartoon, illustration, CGI look, low poly, fantasy shapes,
  melted materials, bad stitching, crooked edges, warped perspective, blurry,
  low resolution, noisy grain, harsh flash, oversaturated, plastic toy look,
  visible brand logos, readable text, watermarks, hands, people, cluttered
  background, unrealistic reflections, leather, metal hardware, embossing,
  UV varnish"

settings: { "aspect_ratio": "2:3", "lens": "50mm", "style": "photorealistic" }
```

**Signature:**
```
prompt_modifier: "Soft-touch paper cover with visible matte texture, spot UV /
  3D varnish ONLY on the wave area (visible wet gloss shimmer), blind embossed
  small logo, two ribbon bookmarks, standard elastic strap, no metal parts"

identity_elements: "chamfered 45-degree top-right corner, two ribbon bookmarks,
  blind embossed hexagonal badge, DNA card with personalization in pocket"

negative_prompt: "cartoon, illustration, CGI look, low poly, fantasy shapes,
  melted materials, bad stitching, crooked edges, warped perspective, blurry,
  low resolution, noisy grain, harsh flash, oversaturated, plastic toy look,
  visible brand logos, readable text, watermarks, hands, people, cluttered
  background, unrealistic reflections, leather, metal hardware"

settings: { "aspect_ratio": "2:3", "lens": "50mm", "style": "photorealistic" }
```

**Lux:**
```
prompt_modifier: "Real leather cover with visible natural grain, deep multi-level
  embossed wave with domed resin lens inlay (glass-like surface), polished faceted
  hexagonal metal badge on magnetic flap closure, two ribbon bookmarks with small
  hex metal tips, painted edge (gold/pearl tint), premium rigid gift box nearby"

identity_elements: "chamfered 45-degree top-right corner, two ribbon bookmarks
  with hexagonal metal tips, polished metal hexagonal badge, magnetic flap
  closure, collector's numbered passport in leather pocket"

negative_prompt: "cartoon, illustration, CGI look, low poly, fantasy shapes,
  melted materials, bad stitching, crooked edges, warped perspective, blurry,
  low resolution, noisy grain, harsh flash, oversaturated, plastic toy look,
  visible brand logos, readable text, watermarks, hands, people, cluttered
  background, unrealistic reflections, paper cover, elastic band, plain ribbons"

settings: { "aspect_ratio": "2:3", "lens": "50mm", "style": "photorealistic,
  manufacturable details, high micro-texture fidelity" }
```

### 10.4. Предпросмотр финального промпта

В интерфейсе управления tier-модификаторами:

- Поле ввода тестового base_prompt
- Кнопка "Preview" → отображение 3 финальных промптов (Core / Signature / Lux)
- Формат финального промпта:

```
{SCENE_SETUP}
{base_prompt}
{tier_modifier.prompt_modifier}
{tier_modifier.identity_elements}
--no {tier_modifier.negative_prompt}
```

- Позволяет убедиться, что модификаторы корректно компонуются

### 10.5. Версионирование

- При изменении tier_modifier — audit_log запись (before/after)
- Генерации, созданные с предыдущей версией модификатора, хранят финальный промпт в `GenerationVariant.final_prompt` (не пересобирается при изменении модификатора)

---

## 11. Дропы (Drops) / Edition numbering (UPDATED v0.2)

### 11.1. Создание дропа

| Поле | Описание |
|------|----------|
| Название | "Drop #1: Minimal Winter" |
| Slug | URL-идентификатор |
| Период | starts_at — ends_at |
| Лимит тиража | Например 300 шт |
| **Коллекция** | Привязка к Collection (опционально) (NEW v0.2) |
| Статус | `"draft"` / `"published"` / `"closed"` |

### 11.2. Привязка к коллекции (NEW v0.2)

- Drop может быть привязан к Collection (FK `collection_id`, nullable)
- Если привязан — дизайны дропа наследуются из коллекции
- Если не привязан — дизайны добавляются вручную (как в v0.1)
- Один дроп = одна коллекция (1:1 опциональная связь)

### 11.3. Наполнение дропа

- Привязка дизайнов к дропу (drop_items)
- Порядок (position)
- Автонумерация edition: "043/300"
- Отдельная витрина дропа на клиенте

### 11.4. Edition numbering UI (NEW v0.2)

| Элемент | Описание |
|---------|----------|
| Таблица edition | Столбцы: номер (001-300), статус (available/reserved/sold), заказ (ссылка) |
| Резервирование | Номер резервируется при создании заказа, подтверждается при оплате |
| Отмена | При отмене заказа — номер возвращается в available |
| Ручное назначение | Админ может назначить конкретный номер конкретному заказу |
| Прогресс | Визуальная шкала: sold / reserved / available |

### 11.5. Stock / Edition management (NEW v0.2)

- Отображение остатка в реальном времени
- Уведомление админу при остатке <= 10%
- Автоматический переход дропа в `"closed"` при sold_out
- Возможность увеличить тираж (admin override) с логированием

### 11.6. Правила продаж

- "Доступно" / "Распродано" (по edition_assignments)
- Нумерация привязывается к order_item при покупке

---

## 12. Управление лимитами / тарифами

### 12.1. Настраиваемые параметры (app_settings)

| Ключ | Описание | Пример |
|------|----------|--------|
| `guest_daily_limit` | Генерации гостя в сутки | 3 |
| `user_daily_limit` | Генерации пользователя в сутки | 30 |
| `unlimited_price_cents` | Цена безлимита | 10000 (100 ₽) |
| `unlimited_duration_hours` | Длительность безлимита | 24 |
| `rate_limit_per_minute` | Макс генераций в минуту | 5 |
| `max_parallel_jobs` | Макс параллельных задач | 2 |
| `core_price_cents` | Цена Core | 200000 |
| `signature_price_cents` | Цена Signature | 300000 |
| `lux_price_cents` | Цена Lux | 1000000 |
| `ai_analysis_parallel_limit` | Макс параллельных AI-анализов | 10 |

### 12.2. Промокоды (опционально)

- Скидка % или фиксированная
- Лимит использований
- Период действия

---

## 13. Аудит-лог

### 13.1. Что логируется

Все действия админов/модераторов:
- `tag.create`, `tag.update`, `tag.delete`, `tag.merge`
- `style.create`, `style.publish`, `style.hide`
- `order.status_change`, `order.refund`
- `design.block`, `design.unblock`
- `settings.update`
- `drop.create`, `drop.publish`
- `collection.create`, `collection.update`, `collection.delete` (NEW v0.2)
- `tier_modifier.update` (NEW v0.2)
- `reference_image.analyze`, `reference_image.curate`, `reference_image.publish` (NEW v0.2)
- `training_batch.create`, `training_batch.analyze` (NEW v0.2)

### 13.2. Структура записи

| Поле | Описание |
|------|----------|
| actor_user_id | Кто сделал |
| action | Что сделал |
| record_type + record_id | Над чем |
| before | Состояние до (JSON) |
| after | Состояние после (JSON) |
| ip | IP-адрес |
| created_at | Когда |

---

## 14. Связь между сущностями (Training Pipeline)

Для понимания потока данных:

```
TrainingBatch (1) ──→ (N) ReferenceImage
                            │
                            ├── ai_analysis_claude (jsonb)
                            ├── ai_analysis_openai (jsonb)
                            ├── selected_provider (string)
                            ├── curated_prompt (text)
                            │
                            ├──→ Collection (FK, optional)
                            │
                            └──→ Design (FK, после публикации)
                                   │
                                   ├──→ GenerationVariant (tier: core)
                                   ├──→ GenerationVariant (tier: signature)
                                   └──→ GenerationVariant (tier: lux)

TierModifier (core)      ──→ prompt_modifier + identity + negative + settings
TierModifier (signature) ──→ prompt_modifier + identity + negative + settings
TierModifier (lux)       ──→ prompt_modifier + identity + negative + settings
```

---

## 15. State machines (Training Pipeline)

### 15.1. TrainingBatch.status (string enum)

```
"uploaded"    -> "processing"   (AI-анализ запущен)
"processing"  -> "completed"    (все reference_images проанализированы)
```

### 15.2. ReferenceImage.status (string enum)

```
"uploaded"    -> "analyzing"    (AI-анализ запущен)
"analyzing"   -> "analyzed"     (AI-анализ завершен)
"analyzed"    -> "curated"      (куратор подтвердил промпт/теги)
"curated"     -> "generated"    (3-tier генерация завершена)
"generated"   -> "published"    (Design создан в каталоге)

# Альтернативные переходы:
"analyzed"    -> "rejected"     (куратор отклонил)
"curated"     -> "rejected"     (отклонен после генерации)
"generated"   -> "rejected"     (все tier-варианты rejected)

# Re-analyze (только если еще не curated):
"analyzed"    -> "analyzing"    (повторный анализ)
```
