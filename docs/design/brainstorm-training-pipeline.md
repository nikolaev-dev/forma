# Brainstorm: Training Pipeline + 3-Tier Design System + Brand Identity

> Дата: 2026-02-15 | Статус: requirements discovery

---

## 1. Суть задачи

400 фотографий реальных блокнотов (обложки). Из них нужно:
1. Извлечь промпты (reverse-engineer через vision AI)
2. Разметить тегами (AI предлагает, куратор подтверждает/правит)
3. Сгруппировать в коллекции
4. Генерировать каждый дизайн в 3 исполнениях: Core / Signature / Lux

---

## 2. Три исполнения — Core / Signature / Lux

**Ключевой инсайт:** разница НЕ эстетическая, а **производственная**. Каждый уровень = другая технология.

### Core — $20 (~2000 руб.)

> "Красивая картинка, но без тактильной магии."

| Параметр | Значение |
|----------|---------|
| Обложка | Бумажная (coated paper wrap), НЕ кожа |
| Печать | Плоская CMYK + ламинация (матовая) |
| Волна | Плоский принт, без рельефа |
| Лак | Нет |
| Тиснение | Нет |
| Металл | Нет |
| Резинка | Стандартная, без шильда |
| Закладки | 2 шт, тканевые, без наконечников |
| Торец | Обычный |
| Бумага | 100 г/м² |

**Промпт-маркеры:** `flat printed cover, coated paper, matte lamination, no metallic, no texture, no embossing, simple elastic band, plain ribbon bookmarks`

### Signature — $30 (~3000 руб.)

> "Берёшь в руки и чувствуешь разницу."

| Параметр | Значение |
|----------|---------|
| Обложка | Бумажная + soft-touch ламинация |
| Печать | CMYK + выборочный UV-лак по волне |
| Волна | Бликующая (spot UV / 3D varnish) |
| Лак | Выборочный UV только по волне |
| Тиснение | Слепое тиснение логотипа |
| Металл | Нет |
| Резинка | Стандартная, без шильда |
| Закладки | 2 шт, тканевые, без наконечников |
| Торец | Обычный |
| Бумага | 100 г/м² |

**Промпт-маркеры:** `soft-touch matte surface, spot UV gloss on wave only (visible glare/shimmer), blind embossed logo, no metal hardware`

### Lux — $100 (~10000 руб.)

> "Другая физика изделия, не просто лак."

| Параметр | Значение |
|----------|---------|
| Обложка | Натуральная кожа с зерном |
| Печать | — (кожа, не печать) |
| Волна | Объёмная: embossing + doming-линза/смоляная заливка |
| Лак | — |
| Тиснение | Multi-level emboss по всей волне |
| Металл | Шестигранный шильд, магнитный замок |
| Замок | Магнитный клапан (не резинка) |
| Закладки | 2 шт с металлическими hex-наконечниками |
| Торец | Окрашенный (edge paint), перламутр/золото |
| Бумага | 120-140 г/м², lay-flat шитый блок |
| Упаковка | Подарочная коробка |

**Промпт-маркеры:** `real leather with visible grain, deep embossed relief wave, domed resin lens inlay, polished hexagonal metal badge, magnetic flap closure, metal-tipped ribbon bookmarks, painted edge (gold/pearl), premium gift box`

### Limited Edition — цена Lux, тираж 30 шт

> "Та же цена, но история + редкость."

- Качество >= Lux
- Каждый экземпляр с **уникальным рисунком** вставки (вариативная печать)
- Нумерация: 1/30...30/30 на шильде
- Особый форзац, особые цвета лент
- Паспорт коллекционера + подпись
- Отдельный знак на торце/замке

**Разница Lux vs Limited:**
- Lux = можно персонализировать (инициалы/надпись/выбор)
- Limited = фиксированный дизайн, но редкость + номер + уникальная вставка

---

## 3. Brand Identity — FORMA DNA

5 элементов, которые присутствуют **в каждом блокноте** (масштабируются по уровню):

### 1. Фирменная S-curve волна на обложке

Одна и та же диагональная траектория на каждой обложке. Рисунок внутри волны меняется, траектория — нет. Это "подпись" бренда сильнее логотипа.

| Уровень | Реализация волны |
|---------|-----------------|
| Core | Плоский принт |
| Signature | Spot UV лак (бликует) |
| Lux | Embossing + doming-линза (объём + глубина) |

### 2. Шестигранный шильд (hexagonal badge)

Грань / кристалл / инженерность. Минимальный брендинг без кричащего логотипа.

| Уровень | Реализация |
|---------|-----------|
| Core | Нет (или мелкий принт) |
| Signature | Слепое тиснение |
| Lux | Полированный металл, ювелирный |

### 3. Две закладки (dual bookmarks)

Всегда две. Фиксированная пара цветов.

| Уровень | Реализация |
|---------|-----------|
| Core | Тканевые, без наконечников |
| Signature | Тканевые, без наконечников |
| Lux | С металлическими hex-наконечниками |

### 4. Один особый угол (chamfered corner)

45° срез на верхнем правом углу. Увидел — узнал.

| Уровень | Реализация |
|---------|-----------|
| Все | Одинаковый срез |

### 5. Карточка FORMA DNA / паспорт

Внутренний кармашек с карточкой: коллекция, номер, дата, QR.

| Уровень | Реализация |
|---------|-----------|
| Core | Простая карточка |
| Signature | Карточка + персонализация |
| Lux / Limited | Паспорт коллекционера, номерной |

---

## 4. Промпт-система

### Структура промпта

```
{SCENE_SETUP}
{DESIGN_PROMPT}        ← из референса (AI + куратор)
{TIER_MODIFIER}        ← Core / Signature / Lux материалы
{IDENTITY_ELEMENTS}    ← волна + шильд + закладки + угол + паспорт
{NEGATIVE_PROMPT}      ← общий для всех
```

### Готовые tier-модификаторы (из answer.md)

**CORE_MODIFIER:**
```
Coated paper wrap cover (NOT leather), matte lamination, flat printed
wave (no UV, no embossing), simple elastic band, two plain ribbon
bookmarks, no metal hardware, no badge, clean minimal product
```

**SIGNATURE_MODIFIER:**
```
Soft-touch paper cover with visible matte texture, spot UV / 3D varnish
ONLY on the wave area (visible wet gloss shimmer), blind embossed small
logo, two ribbon bookmarks, standard elastic strap, no metal parts
```

**LUX_MODIFIER:**
```
Real leather cover with visible natural grain, deep multi-level embossed
wave with domed resin lens inlay (glass-like surface), polished faceted
hexagonal metal badge on magnetic flap closure, two ribbon bookmarks
with small hex metal tips, painted edge (gold/pearl tint), premium
rigid gift box nearby
```

### NEGATIVE_PROMPT (общий)

```
cartoon, illustration, CGI look, low poly, fantasy shapes, melted
materials, bad stitching, crooked edges, warped perspective, blurry,
low resolution, noisy grain, harsh flash, oversaturated, plastic toy
look, visible brand logos, readable text, watermarks, hands, people,
cluttered background, unrealistic reflections, misaligned bookmarks,
extra straps, wrong geometry of the wave, extra corners chamfered,
deformed hexagon
```

### Settings

- Aspect ratio: **2:3** (вертикально, предметная фотосъёмка)
- Lens: **50mm**, soft daylight, shallow DOF
- Style: **photorealistic, manufacturable details, high micro-texture fidelity**

---

## 5. Training Pipeline — обработка 400 референсов

### Флоу

```
Шаг 1: ЗАГРУЗКА
  Куратор загружает пачку фото (drag-n-drop или ZIP)
  → TrainingBatch (status: uploaded)
  → N x ReferenceImage (status: uploaded)

Шаг 2: AI-АНАЛИЗ (Sidekiq, пакетный)
  Vision AI анализирует каждое изображение:
  → Описание (что изображено на обложке)
  → Базовый промпт для воспроизведения дизайна
  → Теги из существующей таксономии (по имени + синонимы + триграммы)
  → Mood / style / dominant colors
  → ReferenceImage (status: analyzed)

Шаг 3: КУРИРОВАНИЕ (админка)
  Куратор для каждого референса:
  → Подтверждает / правит промпт
  → Подтверждает / правит теги
  → Назначает коллекцию
  → ReferenceImage (status: curated)

Шаг 4: ГЕНЕРАЦИЯ 3 УРОВНЕЙ
  Из curated-промпта:
  → PromptTemplate собирает 3 финальных промпта (Core / Signature / Lux)
  → Pipeline генерирует 3 изображения
  → Куратор оценивает (approve / reject / regenerate)

Шаг 5: ПУБЛИКАЦИЯ
  Одобренные → Design в каталоге
  → Привязка к коллекции, стилю, тегам
  → 3 варианта привязаны к Design как tier-варианты
```

### Что Vision AI извлекает из фото

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

## 6. Коллекции

Коллекция — группа дизайнов, объединённых темой/настроением.

### Типы

| Тип | Пример | Тираж |
|-----|--------|-------|
| Regular | "Японские мотивы", "Ботаника" | Без ограничений |
| Limited | "Зимний лес", "Золотая осень" | 30 шт, нумерация |

### Примеры коллекций из 400 референсов

- "Времена года" (4 подколлекции)
- "Городские скетчи"
- "Ботаника"
- "Минимализм"
- "Восточная коллекция"
- "Текстуры и паттерны"
- и т.д. — AI может предложить кластеризацию

---

## 7. Функциональные требования

### FR-1: Загрузка референсов
- Массовая загрузка (drag-n-drop, ZIP)
- Группировка в батчи
- Статусы: uploaded → analyzing → analyzed → curated → generated → published / rejected
- Превью в админке (grid с фильтрами)

### FR-2: AI-анализ изображений
- Vision API (Claude Vision / GPT-4V)
- Извлечение: описание, промпт, теги, mood, цвета, стиль
- Матчинг с существующей таксономией тегов
- Пакетная обработка через Sidekiq
- Стоимость: ~$0.01-0.03/фото = $4-12 за 400

### FR-3: Курирование
- Админ-карточка референса: оригинал + AI-предложения
- Inline-редактирование промпта
- Чипсы тегов с автодополнением
- Назначение коллекции (существующей или новой)
- Bulk-действия: "применить коллекцию ко всем выбранным"

### FR-4: 3-Tier промпт-шаблон
- Шаблон: `{scene} + {design_prompt} + {tier_modifier} + {identity} + {negative}`
- Tier modifiers хранятся в AppSetting или отдельной таблице
- Identity elements — константа бренда
- Предпросмотр финального промпта для каждого уровня в админке

### FR-5: 3-Tier генерация
- Из одного базового промпта → 3 изображения (Core / Signature / Lux)
- Каждый = отдельный GenerationVariant с tier-specific промптом
- Курирование: approve / reject / regenerate по каждому уровню
- Привязка одобренных к Design

### FR-6: Коллекции
- CRUD (имя, slug, описание, обложка, теги)
- Типы: regular / limited
- Limited: edition_size, нумерация
- Привязка дизайнов к коллекциям
- Отображение в каталоге

### FR-7: Выбор уровня при заказе
- Экран S9: 3 визуально разных превью (Core / Signature / Lux)
- Каждый привязан к NotebookSku (цена) + визуальному варианту
- Пользователь видит разницу в дизайне И в цене

---

## 8. Нефункциональные требования

- **Масштаб:** 400 фото сейчас, пачки по 50-100 дальше
- **Скорость:** AI-анализ фоновый (Sidekiq), не блокирует UI
- **Качество:** AI-промпты — стартовая точка, куратор ВСЕГДА правит
- **Идемпотентность:** повторный анализ не затирает курированные данные

---

## 9. Влияние на текущую архитектуру

### Что меняется

| Текущее | Новое |
|---------|-------|
| `GenerationVariant.kind`: main/mutation_a/mutation_b | Добавить: core/signature/lux (или отдельная ось tier) |
| `NotebookSku`: Base(2599)/Pro(3199)/Elite(8999) | Переименовать → Core(2000)/Signature(3000)/Lux(10000) |
| `Style` — пресет генерации | Расширить tier-модификаторами |
| Нет референсов | Новые: `TrainingBatch`, `ReferenceImage` |
| Нет коллекций | Новая: `Collection` |
| `PromptComposer` — один промпт | Расширить: 3 промпта по уровням |
| Мутации = случайная замена тегов | Уровни = производственная адаптация |

### Новые сущности

```
training_batches
├── name, status (uploaded/processing/completed)
├── images_count
└── created_by_user_id (FK)

reference_images
├── training_batch_id (FK)
├── ActiveStorage: original_image
├── status: uploaded/analyzing/analyzed/curated/generated/published/rejected
├── ai_analysis (jsonb): { description, base_prompt, suggested_tags, mood, colors, style, complexity }
├── curated_prompt (text) — финальный промпт после правки
├── collection_id (FK, optional)
├── design_id (FK, после генерации)
└── curator_notes (text)

collections
├── name, slug (unique), description
├── ActiveStorage: cover_image
├── collection_type: string (regular/limited)
├── edition_size (integer, null для regular)
├── is_active (boolean)
└── position (integer)

tier_modifiers (или часть AppSetting)
├── tier: string (core/signature/lux)
├── prompt_modifier (text)
├── identity_elements (text)
├── negative_prompt (text)
└── settings (jsonb): { aspect_ratio, lens, style_notes }
```

---

## 10. Решения по открытым вопросам

| # | Вопрос | Решение |
|---|--------|---------|
| 1 | Vision API | **Оба (A/B)**: прогнать первую пачку через Claude Vision и GPT-4V, сравнить качество промптов, потом выбрать |
| 2 | Переименовать SKU? | **Позже**: пока оставить Base/Pro/Elite, переименовать когда дойдём до реализации tier-системы |
| 3 | Связь оригинал → дизайн | **reference_image → design**: ReferenceImage хранит design_id. Оригинал не публичный |
| 4 | Коллекции vs CatalogSection | **Отдельные сущности**: training pipeline (TrainingBatch, ReferenceImage) живёт отдельно. Результат → Design + Prompt в основной системе. Collection — отдельная от CatalogSection |
| 5 | Tier vs Mutation | **Две оси**: kind (main/mutation_a/mutation_b) остаётся + добавляется tier (core/signature/lux). Итого до 9 вариантов на дизайн |
| 6 | Identity elements | **Фиксированные для всех**: шильд, 2 закладки, срезанный угол, карточка, кармашек, barcode — константы бренда. Волна — НЕ identity, а часть дизайна (может быть любой рисунок) |
| 7 | Лимитки UI | **Да, показывать "осталось X/30"**: stock tracking + FOMO |
| 8 | A/B сравнение | **Да, side-by-side**: куратор видит оригинал слева, 3 генерации (Core/Signature/Lux) справа |

---

## 11. Обновлённая архитектура (после решений)

### Brand Identity — константы (в каждом блокноте)

| Элемент | Core | Signature | Lux |
|---------|------|-----------|-----|
| Шестигранный шильд | Принт (или нет) | Слепое тиснение | Полированный металл |
| 2 закладки | Тканевые | Тканевые | С hex-наконечниками |
| Срезанный угол 45° | Да | Да | Да |
| Карточка/паспорт | Простая | + персонализация | Номерной паспорт |
| Кармашек | Да | Да | Да |
| Barcode | Да | Да | Да |

**Волна — НЕ identity**, а часть дизайна (может быть любой рисунок).

### GenerationVariant — две оси

```
                    core        signature       lux
main            main+core    main+signature   main+lux
mutation_a      mut_a+core   mut_a+signature  mut_a+lux
mutation_b      mut_b+core   mut_b+signature  mut_b+lux
```

Новое поле: `GenerationVariant.tier` (string: core/signature/lux, default: null для обратной совместимости)

### Новые сущности (финальные)

```
training_batches
├── name, status (uploaded/processing/completed)
├── images_count
└── created_by_user_id (FK)

reference_images
├── training_batch_id (FK)
├── ActiveStorage: original_image
├── status: uploaded/analyzing/analyzed/curated/generated/published/rejected
├── ai_analysis_claude (jsonb)     ← результат Claude Vision
├── ai_analysis_openai (jsonb)     ← результат GPT-4V (A/B тест)
├── selected_provider (string)     ← какой промпт выбрал куратор
├── curated_prompt (text)          ← финальный промпт после правки
├── collection_id (FK, optional)
├── design_id (FK, после генерации)
└── curator_notes (text)

collections
├── name, slug (unique), description
├── ActiveStorage: cover_image
├── collection_type: string (regular/limited)
├── edition_size (integer, null для regular)
├── stock_remaining (integer, null для regular)
├── is_active (boolean)
└── position (integer)

tier_modifiers (или AppSetting)
├── tier: string (core/signature/lux)
├── prompt_modifier (text)
├── identity_elements (text)
├── negative_prompt (text)
└── settings (jsonb)
```

### Изменения в существующих моделях

```
GenerationVariant
  + tier: string (core/signature/lux), nullable, default null

Design
  + collection_id: FK (optional)

Order / OrderItem
  + tier: string (для отслеживания какой уровень заказан)
```

---

## 12. Порядок реализации

1. **Коллекции** — миграция, модель Collection, CRUD в админке
2. **Tier-ось** — миграция (GenerationVariant.tier), tier_modifiers
3. **Reference Images** — миграция, загрузка, хранение, статусы
4. **AI-анализ** — Vision API интеграция (оба провайдера), пакетный job
5. **Курирование** — админ-UI: side-by-side оригинал vs AI, правка промптов/тегов
6. **3-Tier генерация** — адаптация Pipeline + PromptComposer (3 промпта × 3 мутации)
7. **Лимитки** — edition numbering, stock tracking, "осталось X/30"
8. **Переработка S9** — визуальный выбор tier с превью Core/Signature/Lux
