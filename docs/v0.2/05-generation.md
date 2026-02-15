# 05. Генерация — FORMA

> Версия: v0.2 | Дата: 2026-02-15

## 1. Ключевые требования

1. Провайдеры генерации подключаются через **единый интерфейс** (сменяемый)
2. Генерация всегда **асинхронная** (Sidekiq)
3. **Два режима генерации:**
   - **Пользовательская** — 3 превью (main + mutation_a + mutation_b), tier = NULL
   - **Training Pipeline** — до 9 вариантов: kind (main/mutation_a/mutation_b) x tier (core/signature/lux)
4. Поддержка **стабильности стиля** (докрутка сохраняет узнаваемость)
5. Встроенная **модерация** промптов/результатов
6. **Tier-система** — производственная разница (технология + материалы) отражена в промптах через TierModifier

---

## 2. Абстракция провайдера (Provider Interface)

### 2.1. Обязательные методы

```ruby
class GenerationProvider
  # Создать генерацию
  def create_generation(request) -> provider_job_id

  # Получить статус
  def get_status(provider_job_id) -> "pending" | "running" | "succeeded" | "failed"

  # Получить результат
  def fetch_result(provider_job_id) -> { images: [...], metadata: {...} }

  # Отменить (опционально)
  def cancel(provider_job_id)
end
```

### 2.2. Параметры запроса

| Параметр | Описание |
|----------|----------|
| prompt | Исходный промпт пользователя (или curated промпт из Training Pipeline) |
| tags | Нормализованные теги (public + hidden) |
| style_preset | Пресет стиля (JSON) |
| seed | Для воспроизводимости (опционально) |
| quality | `"preview"` / `"hires"` |
| policy_flags | Запрет логотипов/брендов |
| tier | `"core"` / `"signature"` / `"lux"` / `nil` (для пользовательских) |

---

## 3. Tier-система (TierModifier)

### 3.1. Назначение

TierModifier описывает **производственную разницу** между уровнями исполнения блокнота. Каждый уровень = другая технология, другие материалы, другой промпт-модификатор для генерации изображений.

Tier-модификаторы применяются **только** для Training Pipeline генераций. Для пользовательских генераций tier = NULL, модификатор не применяется.

### 3.2. Модель TierModifier

```
tier_modifiers
├── id (bigint, PK)
├── tier (string, NOT NULL, UNIQUE) — "core" / "signature" / "lux"
├── prompt_modifier (text, NOT NULL) — производственные характеристики для промпта
├── identity_elements (text, NOT NULL) — элементы бренда (масштабируются по tier)
├── negative_prompt (text, NOT NULL) — запрещенные элементы
├── settings (jsonb, DEFAULT {}) — aspect_ratio, lens, style_notes
├── created_at (datetime)
└── updated_at (datetime)
```

### 3.3. Prompt Modifiers по уровням

#### CORE

```
Coated paper wrap cover (NOT leather), matte lamination, flat printed
wave (no UV, no embossing), simple elastic band, two plain ribbon
bookmarks, no metal hardware, no badge, clean minimal product
```

Суть: красивая картинка, но без тактильной магии. Бумажная обложка, плоская печать, стандартная фурнитура.

#### SIGNATURE

```
Soft-touch paper cover with visible matte texture, spot UV / 3D varnish
ONLY on the wave area (visible wet gloss shimmer), blind embossed small
logo, two ribbon bookmarks, standard elastic strap, no metal parts
```

Суть: берешь в руки и чувствуешь разницу. Soft-touch ламинация, выборочный UV-лак по волне, слепое тиснение.

#### LUX

```
Real leather cover with visible natural grain, deep multi-level embossed
wave with domed resin lens inlay (glass-like surface), polished faceted
hexagonal metal badge on magnetic flap closure, two ribbon bookmarks
with small hex metal tips, painted edge (gold/pearl tint), premium
rigid gift box nearby
```

Суть: другая физика изделия. Натуральная кожа, deep embossing, doming-линза, металл, магнитный замок, окрашенный торец.

### 3.4. Identity Elements (по уровням)

4 обязательных элемента бренда масштабируются по tier:

| Элемент | Core | Signature | Lux |
|---------|------|-----------|-----|
| **Hex badge** (шестигранный шильд) | Мелкий принт (или отсутствует) | Слепое тиснение | Полированный металл, ювелирный |
| **Dual bookmarks** (2 закладки) | Тканевые, без наконечников | Тканевые, без наконечников | С металлическими hex-наконечниками |
| **Chamfered corner 45°** (срезанный угол) | Да | Да | Да |
| **DNA card / passport** (карточка) | Простая карточка | + персонализация (инициалы) | Номерной паспорт коллекционера |

**Волна (wave) — опциональный стилевой элемент**, не обязательный identity. Может использоваться как часть дизайна, но не является обязательным атрибутом бренда.

### 3.5. Negative Prompt (общий для всех уровней)

```
cartoon, illustration, CGI look, low poly, fantasy shapes, melted
materials, bad stitching, crooked edges, warped perspective, blurry,
low resolution, noisy grain, harsh flash, oversaturated, plastic toy
look, visible brand logos, readable text, watermarks, hands, people,
cluttered background, unrealistic reflections, misaligned bookmarks,
extra straps, wrong geometry of the wave, extra corners chamfered,
deformed hexagon
```

### 3.6. Settings (общие)

```json
{
  "aspect_ratio": "2:3",
  "lens": "50mm",
  "lighting": "soft daylight, shallow depth of field",
  "style": "photorealistic, manufacturable details, high micro-texture fidelity"
}
```

---

## 4. Сборка промпта (Prompt Composer)

### 4.1. Назначение

Сервис формирует **финальный промпт** для генерации. Поддерживает два режима:

- **Пользовательская генерация** — промпт из текста + стиль + теги (как в v0.1)
- **Training Pipeline** — промпт из curated-референса + tier modifier + identity

### 4.2. Шаблон промпта

```
{scene_setup} + {design_prompt} + {tier_modifier} + {identity_elements} + {negative_prompt}
```

| Блок | Пользовательская генерация | Training Pipeline |
|------|---------------------------|-------------------|
| `scene_setup` | Стандартная сцена (предметная съемка) | Стандартная сцена (предметная съемка) |
| `design_prompt` | Текст пользователя + стиль + теги | Curated промпт из референса |
| `tier_modifier` | **Не применяется** (tier = NULL) | Из TierModifier для указанного tier |
| `identity_elements` | **Не применяется** | Из TierModifier (масштабированы по tier) |
| `negative_prompt` | Системный суффикс (no logos, no brands) | Из TierModifier (общий) |

### 4.3. Пользовательская генерация (без tier)

Работает так же, как в v0.1:

1. Текст пользователя
2. Выбранный стиль (тон/эстетика)
3. Теги (публичные)
4. Скрытые теги (аккуратно)
5. Системные ограничения (без логотипов, без копирования)

Принцип:
- Brand-теги -> mood, а не "нарисуй логотип"
- Системный суффикс: "no logos, no brand names, no copyrighted characters"
- Стиль влияет на "тон" промпта (минимализм -> чистые линии, мало деталей)

### 4.4. Training Pipeline генерация (с tier)

Для каждого tier формируется отдельный промпт:

```ruby
# Пример для Core:
composed_prompt = [
  scene_setup,           # "Photorealistic premium product photography of an A5 lay-flat notebook..."
  curated_prompt,        # "Japanese zen garden in autumn, red maple trees..."
  tier_modifier.prompt,  # "Coated paper wrap cover (NOT leather), matte lamination..."
  tier_modifier.identity # "small printed hexagonal badge, two plain ribbon bookmarks..."
].join(". ")

negative = tier_modifier.negative_prompt
```

### 4.5. Выходной формат

```json
{
  "composed_prompt": "final text for provider...",
  "tags_used": ["gold", "minimalism", "japan"],
  "hidden_tags_used": ["warm_palette", "geometric"],
  "policy_applied": ["no_logos", "brand_mood_only"],
  "tier": "core",
  "tier_modifier_applied": true
}
```

Для пользовательской генерации: `tier = null`, `tier_modifier_applied = false`.

---

## 5. Мутации (Tag Mutation Engine)

### 5.1. Правило

При каждом "Сгенерировать":
- **1 основной** результат (по промпту пользователя)
- **+2 мутации**, в которые подбрасываются 1-2 тега (или замена)

Мутации работают **только для пользовательских генераций** (tier = NULL). В Training Pipeline мутации не используются — вместо них генерация по 3 уровням (tier).

### 5.2. Алгоритм подбора тегов

Теги берутся из:
1. **Предпочтения пользователя** (лайки стилей -> user_tag_affinities)
2. **Контекст промпта** (связанные теги через tag_relations)
3. **Глобальные тренды** (популярные теги, опционально)
4. **Допустимые категории** (без конфликтующих)

### 5.3. Ограничения

- Не повторять теги, которые уже есть
- Не подбрасывать запрещенные (is_banned)
- Избегать бессмысленных сочетаний (tag_relations: conflicts_with)
- Не подбрасывать рискованные brand-теги без флага brand_mood

### 5.4. Генерация объяснения

Каждая мутация формирует `mutation_summary`:
- "Заменили золото -> серебро"
- "Добавили: tiffany mood, минимализм"
- "Усилили: строгость"

### 5.5. UI

На превью мутации показывается:
- Плашка с объяснением
- Кнопка "Принять изменения" (делает мутацию новым основным)

---

## 6. GenerationVariant — две оси

### 6.1. Поле `tier` на GenerationVariant

Новое поле: `GenerationVariant.tier` (string: `"core"` / `"signature"` / `"lux"`, nullable).

- **Пользовательская генерация:** tier = NULL. Ось только kind (main/mutation_a/mutation_b) = 3 варианта. Поведение идентично v0.1.
- **Training Pipeline:** kind x tier = до 9 вариантов.

### 6.2. Матрица вариантов (Training Pipeline)

```
                    core            signature           lux
main            main+core       main+signature      main+lux
mutation_a      mut_a+core      mut_a+signature      mut_a+lux
mutation_b      mut_b+core      mut_b+signature      mut_b+lux
```

В Training Pipeline **типичный сценарий** — 3 варианта (main x 3 tiers). Мутации по оси kind в рамках Training Pipeline **опциональны** (куратор может запросить).

### 6.3. Unique constraint

Для пользовательских генераций (tier = NULL):
- Unique: `[generation_id, kind]` (как в v0.1)

Для Training Pipeline генераций (tier != NULL):
- Unique: `[generation_id, kind, tier]`

Реализация: составной partial unique index.

---

## 7. Пайплайн генерации

### 7.1. Пользовательская генерация (MVP, как v0.1)

```
1. Пользователь нажимает "Сгенерировать"
   |
2. Создать Generation (status: "created", source: "user")
   |
3. Сформировать 3 GenerationVariant (tier: NULL):
   - Main (kind: "main")
   - MutA (kind: "mutation_a") + выбрать мутационные теги
   - MutB (kind: "mutation_b") + выбрать мутационные теги
   |
4. Для каждого варианта:
   - PromptComposer -> composed_prompt (без tier modifier)
   - Отправить провайдеру (параллельно, с лимитами)
   |
5. Generation.status -> "queued" -> "running"
   |
6. Получить результаты от провайдера
   - Сохранить изображения в Object Storage (ActiveStorage)
   - Variant.status -> "succeeded" / "failed"
   |
7. Пост-обработка:
   - Генерация мокапа блокнота (наложение на шаблон)
   - Генерация thumbnail
   |
8. Generation.status -> "succeeded" / "partial" / "failed"
   |
9. Отдать клиенту 3 карточки превью
```

### 7.2. Training Pipeline генерация

```
1. Куратор выбирает curated ReferenceImage и нажимает "Сгенерировать 3 уровня"
   |
2. Создать Generation (status: "created", source: "training_pipeline")
   Привязка: generation.reference_image_id
   |
3. Сформировать 3 GenerationVariant (kind: "main"):
   - Core  (kind: "main", tier: "core")
   - Signature (kind: "main", tier: "signature")
   - Lux   (kind: "main", tier: "lux")
   |
4. Для каждого варианта:
   - PromptComposer -> composed_prompt (с tier modifier из TierModifier)
   - Шаблон: {scene_setup} + {curated_prompt} + {tier_modifier} + {identity} + {negative}
   - Отправить провайдеру (параллельно)
   |
5. Generation.status -> "queued" -> "running"
   |
6. Получить результаты от провайдера
   - Сохранить изображения в Object Storage (ActiveStorage)
   - Variant.status -> "succeeded" / "failed"
   |
7. Пост-обработка:
   - Генерация мокапа блокнота (наложение на шаблон)
   - Генерация thumbnail
   |
8. Generation.status -> "succeeded" / "partial" / "failed"
   |
9. Курирование:
   - Куратор видит 3 результата (Core / Signature / Lux) рядом с оригиналом
   - Для каждого: approve / reject / regenerate
   |
10. Публикация:
    - Одобренные варианты -> Design в каталоге
    - Привязка к коллекции, стилю, тегам
    - reference_image.status -> "published"
```

### 7.3. Полная схема Training Pipeline (end-to-end)

```
Reference Image (curated) →
  PromptComposer builds 3 prompts (one per tier) →
  3 x GenerationVariant (tier: core/signature/lux) →
  Provider.create_generation() per variant →
  Results → ActiveStorage →
  Curator approves/rejects/regenerates each →
  Approved → Design in catalog
```

---

## 8. State Machines

### 8.1. Generation

```
"created" -> "queued"    (поставлена в очередь Sidekiq)
"queued"  -> "running"   (провайдер начал обработку)
"running" -> "partial"   (1-2 варианта готовы, остальные еще нет / упали)
"running" -> "succeeded" (все варианты готовы)
"running" -> "failed"    (все варианты упали)
"partial" -> "succeeded" (оставшиеся варианты готовы)
"partial" -> "failed"    (timeout или все оставшиеся упали)
*         -> "canceled"  (пользователь/куратор отменил)
```

### 8.2. GenerationVariant

```
"created"  -> "queued"     (отправлен провайдеру)
"queued"   -> "running"    (провайдер обрабатывает)
"running"  -> "succeeded"  (результат получен)
"running"  -> "failed"     (ошибка провайдера)
```

---

## 9. Качество и форматы изображений

### 9.1. Производственные форматы

| Формат | Назначение | Размер |
|--------|-----------|--------|
| thumb | Быстрая загрузка (списки, витрина) | ~200px |
| preview | Для выбора (экран результатов) | ~800px |
| hires | Для печатного макета обложки | ~2400px+ |
| mockup | Мокап на блокноте | ~1200px |

### 9.2. Печать

- Итоговый файл обложки: **print-ready PDF**
- Параметры формата/bleed/поля — конфигурируемые в админке
- Внутренний блок: **print-ready PDF**
- MVP: RGB -> PDF. В будущем: CMYK + профили

---

## 10. Модерация

### 10.1. Фильтр промптов

- Словарь запрещенных слов/тем
- Проверка перед отправкой провайдеру
- Блок или `moderation_status: "requires_review"`

### 10.2. Фильтр результатов

- Флаг `requires_review` для спорных случаев
- Автодетекция (опционально, фаза 2)

### 10.3. Запрет генерации

- Логотипов
- Точных копий фирменных персонажей/маскотов
- Прямых упаковок/этикеток

### 10.4. Жалобы

- Кнопка "Пожаловаться" на публичной странице дизайна
- Запись в moderation_reports
- Очередь модерации для модератора/админа

---

## 11. Brand Identity в промптах

### 11.1. Обязательные элементы

4 обязательных элемента присутствуют в промптах Training Pipeline и масштабируются по tier:

#### 1. Hex badge (шестигранный шильд)

Минимальный брендинг: грань / кристалл / инженерность. Без кричащего логотипа.

| Core | Signature | Lux |
|------|-----------|-----|
| Мелкий принт на обложке | Слепое тиснение (blind emboss) | Полированный металл, ювелирный, на магнитном клапане |

Промпт:
- Core: `small printed hexagonal badge` (или без шильда)
- Signature: `blind embossed small hexagonal logo`
- Lux: `polished faceted hexagonal metal badge on magnetic flap closure`

#### 2. Dual bookmarks (2 закладки)

Всегда две. Фиксированная пара цветов для бренда.

| Core | Signature | Lux |
|------|-----------|-----|
| Тканевые, без наконечников | Тканевые, без наконечников | С металлическими hex-наконечниками |

Промпт:
- Core/Signature: `two plain ribbon bookmarks`
- Lux: `two ribbon bookmarks with small hex metal tips`

#### 3. Chamfered corner 45° (срезанный угол)

Верхний правый угол. Увидел — узнал. Одинаковый на всех уровнях.

Промпт (все): `distinctive 45-degree chamfer on the top-right corner`

#### 4. DNA card / passport (карточка)

Внутренний кармашек с карточкой: коллекция, номер, дата, QR.

| Core | Signature | Lux / Limited |
|------|-----------|---------------|
| Простая карточка | + персонализация (инициалы) | Номерной паспорт коллекционера |

Промпт:
- Core: `inner back pocket with a simple collectible card partially visible`
- Signature: `inner back pocket with a personalized collectible passport card`
- Lux: `inner back pocket with a numbered collector passport certificate`

### 11.2. Волна (wave) — опциональный элемент

S-curve волна на обложке — **рекомендуемый стилевой элемент, но не обязательный identity**. Не является обязательным атрибутом бренда.

Если используется в дизайне:

| Core | Signature | Lux |
|------|-----------|-----|
| Плоский принт | Spot UV лак (бликует) | Embossing + doming-линза (объём + глубина) |

### 11.3. Пользовательские генерации

Brand identity в пользовательских генерациях **не применяется**. Пользователь генерирует дизайн обложки как визуальную концепцию, без привязки к конкретному уровню исполнения. Уровень выбирается позже, при заказе (экран S9).

---

## 12. Логи и наблюдаемость

### 12.1. Что логировать

| Данные | Описание |
|--------|----------|
| Финальный промпт | С маскированием чувствительных частей |
| Теги/мутации | Какие подбросили |
| Провайдер, модель | Кто генерировал |
| Время | started_at, finished_at, latency |
| Стоимость/квота | Если учитываете |
| Ошибки | error_code, error_message |
| Tier | Какой уровень генерировался (NULL для пользовательских) |
| Source | "user" / "training_pipeline" |

### 12.2. Метрики

| Метрика | Описание |
|---------|----------|
| time-to-preview | От запуска до готового превью |
| conversion: generation -> select -> order | Воронка |
| share rate | Доля дизайнов, которыми поделились |
| repeat generation rate | Повторные генерации (докрутки) |
| mutation acceptance rate | Как часто выбирают мутацию вместо основного |
| tier distribution | Распределение заказов по Core/Signature/Lux |
| training pipeline throughput | Сколько дизайнов/день через pipeline |
| curator approval rate | % одобренных генераций из Training Pipeline |

---

## 13. Связь с другими документами

| Тема | Документ |
|------|----------|
| Схема БД (generation_variants, tier_modifiers) | `06-storage.md` |
| Training Pipeline (загрузка, AI-анализ, курирование) | `08-training-pipeline.md` |
| Заказы и выбор уровня (S9) | `07-orders-payments.md` |
| Экраны пользовательской генерации | `02-user-stories.md` |
| Админка (управление tier_modifiers, курирование) | `04-admin.md` |
