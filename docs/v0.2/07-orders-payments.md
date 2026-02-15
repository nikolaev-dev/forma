# 07. Заказы и оплата — FORMA

> Версия: v0.2 | Дата: 2026-02-15

## Изменения относительно v0.1

- **Tier в заказах:** OrderItem получает поле `tier` (core/signature/lux), определяющее цену и производственные спецификации
- **NotebookSku переименован:** base -> core, pro -> signature, elite -> lux (цены TBD)
- **S9 обновлен:** визуальный выбор уровня с 3 разными превью для каталожных дизайнов
- **Limited edition stock tracking:** отслеживание остатков, pessimistic locking, edition numbering
- **Collection в заказах:** OrderItem может ссылаться на Collection для аналитики
- **DNA Card tier-aware:** разная карточка для Core / Signature / Lux / Limited
- **Cover print PDF tier-aware:** разные производственные спецификации по уровням

---

## 1. ЮKassa (YooKassa)

### 1.1. Интеграция

- Оплата через YooKassa Checkout (redirect или виджет)
- Получение статусов через **webhooks**
- Idempotence key для защиты от дублей

### 1.2. Поток оплаты заказа

```
1. Пользователь нажимает "Оплатить"
2. Backend создает Payment (status: "created")
3. Backend отправляет запрос в YooKassa API:
   - amount, currency, description
   - confirmation: { type: "redirect", return_url: "..." }
   - metadata: { order_id: ... }
4. YooKassa возвращает confirmation_url
5. Redirect пользователя на confirmation_url
6. Пользователь оплачивает
7. YooKassa вызывает webhook
8. Backend обновляет Payment.status
9. Если "succeeded" -> Order.status = "paid"
   -> Если заказ из limited Collection/Drop: assign edition, decrement stock
10. Redirect на return_url -> экран "Заказ принят"
```

### 1.3. Статусы платежа (string enum)

```
"created"    -> начальный
"pending"    -> ожидает подтверждения
"succeeded"  -> оплачен
"canceled"   -> отменен пользователем
"failed"     -> ошибка
"refunded"   -> возврат
```

### 1.4. Webhook обработка

- Endpoint: `POST /payments/yookassa/webhook`
- **Идемпотентность:** проверка `provider_payment_id` + `status`
- **Валидация:** проверка IP YooKassa, подпись (если есть)
- **Хранение:** полный payload в `payments.raw` (jsonb)

### 1.5. Что хранить

| Поле | Описание |
|------|----------|
| provider_payment_id | ID платежа в YooKassa |
| status | Текущий статус |
| amount_cents | Сумма в копейках |
| idempotence_key | Ключ идемпотентности |
| confirmation_url | URL для редиректа |
| captured_at | Время подтверждения |
| raw | Весь JSON от YooKassa |

## 2. Штрихкод

### 2.1. Генерация

Каждый заказ получает:
- **order_number** — человекочитаемый (FORMA-2026-000123)
- **barcode_value** — строка для штрихкода
- **barcode_type** — Code128 (рекомендовано)

### 2.2. Где отображается

| Место | Формат |
|-------|--------|
| Админка (карточка заказа) | Изображение + текст |
| Профиль пользователя (мои заказы) | Изображение |
| PDF лист комплектации | Печатный |
| PDF наклейки (пакетная печать) | Печатный |

### 2.3. Генерация штрихкода

Использовать gem `barby` или аналог для генерации Code128 -> SVG/PNG.

## 3. Статусы заказа

### 3.1. State Machine (string enum)

```
"draft"             -> "awaiting_payment"   (пользователь заполнил форму)
"awaiting_payment"  -> "paid"               (webhook: payment succeeded)
"awaiting_payment"  -> "canceled"           (timeout или отмена)
"paid"              -> "in_production"      (админ: "В производство")
"in_production"     -> "shipped"            (админ: "Отправлен" + трек)
"shipped"           -> "delivered"          (админ: "Доставлен")
"paid"              -> "canceled"           (до производства)
"paid"              -> "refunded"           (возврат через YooKassa)
```

### 3.2. Допустимые переходы

| Из | В | Кто | Условие |
|----|---|-----|---------|
| draft | awaiting_payment | система | Форма заполнена |
| awaiting_payment | paid | webhook | Payment succeeded |
| awaiting_payment | canceled | система/пользователь | Timeout / отмена |
| paid | in_production | админ | Кнопка |
| in_production | shipped | админ | Кнопка + трек |
| shipped | delivered | админ | Кнопка |
| paid | canceled | админ | До производства |
| paid | refunded | админ | Через YooKassa refund |

### 3.3. Side effects при переходе в "paid"

При переходе Order в статус `"paid"` выполняется цепочка side effects:

```
Order.status -> "paid"
  1. Генерация order_number (FORMA-YYYY-NNNNNN)
  2. Генерация barcode_value
  3. Если OrderItem привязан к limited Collection или Drop:
     a. Assign edition_number через EditionAssignment
     b. Decrement stock_remaining (Collection) или mark edition (Drop)
  4. Запуск OrderFileGenerationJob:
     - cover_print_pdf (tier-aware)
     - inner_print_pdf
     - dna_card_pdf (tier-aware)
     - packing_slip_pdf
  5. Email / уведомление пользователю
```

## 4. Tier (уровень исполнения) в заказах

### 4.1. NotebookSku — уровни

> **Переименование в v0.2:** base -> core, pro -> signature, elite -> lux

| code | Название | Цена | Суть |
|------|----------|------|------|
| `"core"` | FORMA Core | TBD | Красивая картинка, хороший массовый продукт |
| `"signature"` | FORMA Signature | TBD | Берешь в руки и чувствуешь разницу |
| `"lux"` | FORMA Lux | TBD | Другая физика изделия |

Цены хранятся в `notebook_skus.price_cents` и могут изменяться админом.

### 4.2. OrderItem.tier

OrderItem получает поле `tier` (string enum: `"core"`, `"signature"`, `"lux"`):

```ruby
# OrderItem
enum :tier, { core: "core", signature: "signature", lux: "lux" }

# tier определяется через notebook_sku_id при создании OrderItem
# tier сохраняется как snapshot — если NotebookSku изменится позже, OrderItem сохранит tier на момент заказа
```

**Зачем дублировать tier, если есть notebook_sku_id?**
- `notebook_sku_id` — FK на текущую запись (может измениться)
- `tier` — snapshot уровня на момент заказа (неизменяемый)
- Используется для роутинга производственных спецификаций и DNA Card

### 4.3. Влияние tier на производство

| Аспект | Core | Signature | Lux |
|--------|------|-----------|-----|
| **Обложка** | Coated paper wrap, ламинация | Soft-touch ламинация, spot UV | Натуральная кожа |
| **Технология** | Плоская печать | + тиснение, UV лак | Deep embossing, doming, металл |
| **DNA Card** | Простая карточка | + персонализация (инициалы) | Номерной паспорт коллекционера |
| **Cover PDF спеки** | Стандартный layout | + зоны для UV/тиснения | + зоны для embossing, edge paint |

### 4.4. S9 — экран выбора уровня (обновление v0.2)

> Переименование: "Комплектация Base / Pro / Elite" -> "Уровень Core / Signature / Lux"

**Для каталожных дизайнов (из Collection/Training Pipeline):**
- 3 карточки с реальными превью разного качества (3 разных изображения, сгенерированные через tier_modifiers)
- Каждая карточка: preview image + название уровня + цена + краткое описание отличий
- Signature выделена по умолчанию (recommended)
- Lux: плашка "Коллекционный уровень" (или "Лимитированный" для limited коллекций)

**Для пользовательских генераций:**
- 3 карточки с одним и тем же превью (мокапы с разной отделкой)
- Описание физических отличий по уровням

**CTA:** "Оформить заказ" -> S10

## 5. Limited edition stock tracking

### 5.1. Источники лимитированного тиража

Лимитированный тираж может быть у:

1. **Collection** (type: `"limited"`) — `stock_remaining` в таблице `collections`
2. **Drop** — `edition_limit` в таблице `drops`, нумерация через `edition_assignments`

### 5.2. Проверка доступности при заказе

```ruby
# Псевдокод: при переходе draft -> awaiting_payment
def validate_stock!(order_item)
  if order_item.collection&.limited?
    raise OutOfStockError if order_item.collection.stock_remaining <= 0
  end

  if order_item.drop.present?
    available = order_item.drop.edition_assignments
                  .where(status: "reserved", order_item_id: nil)
    raise OutOfStockError if available.empty?
  end
end
```

### 5.3. Присвоение edition при оплате

При переходе Order в `"paid"`:

```ruby
# Псевдокод: assign edition с pessimistic locking
def assign_edition!(order_item)
  return unless limited_edition?(order_item)

  ActiveRecord::Base.transaction do
    if order_item.collection&.limited?
      collection = Collection.lock.find(order_item.collection_id)
      raise OutOfStockError if collection.stock_remaining <= 0
      collection.decrement!(:stock_remaining)
    end

    if order_item.drop.present?
      assignment = EditionAssignment
        .lock
        .where(drop_id: order_item.drop_id, status: "reserved", order_item_id: nil)
        .order(:edition_number)
        .first!

      assignment.update!(
        order_item_id: order_item.id,
        status: "assigned"
      )
    end
  end
end
```

### 5.4. Race condition handling

**Проблема:** два пользователя оплачивают последний экземпляр одновременно.

**Решение:** pessimistic locking (`SELECT ... FOR UPDATE`) на:
- `collections` row при декременте `stock_remaining`
- `edition_assignments` row при назначении edition_number

**Гарантии:**
- Один экземпляр = один покупатель (уникальность через DB constraint)
- Если stock закончился между checkout и оплатой — refund через YooKassa + уведомление пользователю
- `EditionAssignment` unique index: `[drop_id, edition_number]` — DB-level защита от дублей

### 5.5. Отмена/возврат лимитированного заказа

При отмене или возврате (Order -> `"canceled"` / `"refunded"`):

```ruby
def release_edition!(order_item)
  ActiveRecord::Base.transaction do
    if order_item.collection&.limited?
      collection = Collection.lock.find(order_item.collection_id)
      collection.increment!(:stock_remaining)
    end

    if order_item.drop.present?
      assignment = EditionAssignment
        .where(order_item_id: order_item.id)
        .first
      assignment&.update!(order_item_id: nil, status: "reserved")
    end
  end
end
```

### 5.6. Отображение stock в UI

| Место | Что показывать |
|-------|---------------|
| Карточка дизайна в каталоге | "Осталось 12 из 300" (если limited) |
| S9 (выбор уровня) | "Лимитированный тираж: 43/300" |
| S12 (заказ принят) | "Ваш экземпляр: 043/300" |
| DNA Card | "043/300" |

## 6. Collection в заказах

### 6.1. OrderItem.collection_id

OrderItem может опционально ссылаться на Collection:

```
order_items.collection_id -> FK (nullable) -> collections.id
```

**Зачем:**
- Аналитика: какие коллекции продаются лучше
- Stock tracking для limited коллекций
- Информация для DNA Card (название коллекции)

### 6.2. Влияние Collection на DNA Card

DNA Card включает информацию о коллекции, если OrderItem привязан к Collection:

| Поле DNA Card | Без коллекции | С коллекцией (regular) | С коллекцией (limited) |
|---------------|---------------|----------------------|----------------------|
| Название коллекции | -- | "Коллекция: Северные моря" | "Коллекция: Северные моря" |
| Edition info | -- | -- | "043/300" |
| Дата | Дата заказа | Дата заказа | Дата заказа |
| QR | На страницу дизайна | На страницу дизайна | На страницу дизайна |

### 6.3. Drop-specific информация

Если OrderItem из Drop:

| Поле DNA Card | Значение |
|---------------|----------|
| Название дропа | "Drop: Сезон Бури" |
| Edition | "043/300" |
| Дата дропа | starts_at из Drop |
| Статус | "Limited Edition" |

## 7. Файлы производства

### 7.1. Типы файлов (string enum)

| Тип | Описание | Генерация |
|-----|----------|----------|
| `"cover_print_pdf"` | Обложка для печати | После оплаты, hires -> PDF (tier-aware) |
| `"inner_print_pdf"` | Внутренний блок | По filling + settings |
| `"dna_card_pdf"` | DNA Card | Шаблон + данные дизайна (tier-aware) |
| `"packing_slip_pdf"` | Лист комплектации | Данные заказа + штрихкод |
| `"preview_pack_zip"` | Пакет превью (для сверки) | Все варианты |

### 7.2. Статусы файлов (string enum)

```
"created"   -> "rendering"  (Sidekiq job запущен)
"rendering" -> "ready"      (файл загружен в S3)
"rendering" -> "failed"     (ошибка генерации)
```

### 7.3. Генерация после оплаты

При переходе заказа в `"paid"`:
1. Запускается Sidekiq job `OrderFileGenerationJob`
2. Генерация: cover_print_pdf, inner_print_pdf, dna_card_pdf, packing_slip_pdf
3. Файлы загружаются в ActiveStorage (S3)
4. order_files.status -> "ready"

### 7.4. Cover print PDF — tier-aware спецификации

Cover PDF генерируется с учетом tier OrderItem:

| Tier | Спецификации PDF |
|------|-----------------|
| **Core** | Стандартный layout: bleed marks, crop marks, CMYK. Формат под плоскую печать на coated paper |
| **Signature** | + Отдельный слой/файл для spot UV зон (волна, акценты). + Зоны для слепого тиснения (шильд). Soft-touch finish mark |
| **Lux** | + Зоны для deep embossing. + Маска для doming-линзы. + Edge paint color spec. Формат под кожу (с учетом зерна) |

```ruby
# Псевдокод: CoverPrintPdfGenerator
class CoverPrintPdfGenerator
  def generate(order_item)
    tier = order_item.tier
    design = order_item.design

    case tier
    when "core"
      generate_standard_cover(design)
    when "signature"
      generate_standard_cover(design)
        .add_spot_uv_layer(design)
        .add_blind_emboss_zones(design)
    when "lux"
      generate_leather_cover(design)
        .add_deep_emboss_zones(design)
        .add_doming_mask(design)
        .add_edge_paint_spec(design)
    end
  end
end
```

### 7.5. DNA Card PDF — tier-aware содержимое

DNA Card различается по tier:

#### Core — простая карточка

```
+---------------------------+
|  FORMA DNA                |
|                           |
|  Дизайн: "Северное сияние"|
|  Стиль: Минимализм        |
|  Дата: 15.02.2026         |
|                           |
|  [QR]  forma.ru/d/k5dm8p  |
+---------------------------+
```

#### Signature — персонализированная карточка

```
+---------------------------+
|  FORMA DNA                |
|                           |
|  Дизайн: "Северное сияние"|
|  Стиль: Минимализм        |
|  Коллекция: Северные моря |
|  Дата: 15.02.2026         |
|                           |
|  Инициалы: А.Н.           |
|                           |
|  [QR]  forma.ru/d/k5dm8p  |
+---------------------------+
```

> Инициалы берутся из `customer_name` заказа или вводятся отдельно на S10.

#### Lux / Limited — номерной паспорт коллекционера

```
+---------------------------+
|  FORMA DNA PASSPORT       |
|                           |
|  Дизайн: "Северное сияние"|
|  Стиль: Минимализм        |
|  Коллекция: Северные моря |
|  Drop: Сезон Бури         |
|  Экземпляр: 043/300       |
|  Дата: 15.02.2026         |
|                           |
|  Инициалы: А.Н.           |
|  Уровень: Lux             |
|                           |
|  [QR]  forma.ru/d/k5dm8p  |
|                           |
|  FORMA — редакция вкуса   |
+---------------------------+
```

> Для limited-коллекций DNA Card включает edition info ("043/300") на любом tier, но полный формат паспорта — только для Lux и Limited.

### 7.6. Логика выбора шаблона DNA Card

```ruby
# Псевдокод
def dna_card_template(order_item)
  if order_item.edition_assignment.present? || order_item.tier == "lux"
    :passport  # номерной паспорт
  elsif order_item.tier == "signature"
    :personalized  # с инициалами
  else
    :simple  # базовая карточка
  end
end
```

## 8. Лимиты и монетизация генераций

### 8.1. Лимиты

| Тип пользователя | Лимит | Антиабуз |
|-------------------|-------|----------|
| Гость | 2-5 в сутки (настраивается) | IP + fingerprint |
| Авторизованный | 20-50 в сутки (настраивается) | user_id |
| Безлимит (100 ₽) | Без лимита на период | Rate limit + parallel limit |

### 8.2. Подсчет лимита

- Таблица `usage_counters`: user_id/anonymous_identity_id + period (date)
- Инкремент при каждой генерации
- Проверка перед стартом генерации

### 8.3. Безлимит на период

- **Стоимость:** 100 ₽ (настраивается)
- **Период:** 24 часа (настраивается)
- **Fair Use Policy:**
  - Rate limit: не больше X генераций в минуту
  - Лимит параллельных задач: 1-2 одновременно
- **Оплата:** через YooKassa (payable_type: "GenerationPass")

### 8.4. State Machine: GenerationPass

```
"active"   -> "expired"    (ends_at прошло)
"active"   -> "canceled"   (возврат)
```

### 8.5. Проверка доступа к генерации

```ruby
# Псевдокод
def can_generate?(user_or_anon)
  # 1. Есть активный безлимит?
  return true if active_generation_pass?(user_or_anon)

  # 2. Проверить дневной лимит
  counter = usage_counter_for_today(user_or_anon)
  limit = user_or_anon.is_a?(User) ? app_settings.user_daily_limit : app_settings.guest_daily_limit

  counter.generations_count < limit
end
```

## 9. Оформление заказа (UX-поток)

### 9.1. Данные формы

| Поле | Обязательное | Валидация |
|------|-------------|-----------|
| customer_name | Да | min 2 символа |
| customer_phone | Да | Формат телефона |
| customer_email | Да | Формат email |
| shipping_method | Если есть доставка | Из списка |
| shipping_address | Если доставка | Структурно (город, улица...) |
| initials | Нет (Signature/Lux) | 2-4 символа, кириллица/латиница + точки |
| notes | Нет | До 500 символов |

> `initials` — опциональное поле, отображаемое для tier Signature и Lux. Используется для персонализации DNA Card. Если не заполнено, инициалы извлекаются из `customer_name`.

### 9.2. Итоговая сумма

```
subtotal = order_items.sum(total_price_cents)
shipping = shipping_rate(method, address)
total = subtotal + shipping
```

### 9.3. Нумерация заказа

Формат: `FORMA-{year}-{sequential_6digit}`

Примеры:
- `FORMA-2026-000001`
- `FORMA-2026-000123`

Номер генерируется при переходе Order в `"paid"`, **не при создании draft**.

### 9.4. После оплаты

1. Order.status -> "paid"
2. Генерация order_number: `FORMA-{year}-{sequential_6digit}`
3. Генерация barcode_value
4. Если limited edition: assign edition (см. раздел 5.3)
5. Запуск генерации файлов производства (tier-aware)
6. Показ экрана "Заказ принят" (S12) с QR + номером + edition info (если limited)

### 9.5. S12 — заказ принят (обновление v0.2)

Экран подтверждения включает:

| Элемент | Всегда | Limited only |
|---------|--------|-------------|
| Номер заказа | + | + |
| Статус | + | + |
| QR на страницу дизайна | + | + |
| Уровень (Core/Signature/Lux) | + | + |
| Коллекция | если есть | + |
| Edition ("043/300") | -- | + |
| "Отслеживать заказ" | + | + |
| "Сделать еще один" | + | + |

## 10. Полная схема: от выбора до оплаты

```
Пользователь выбирает дизайн (каталог или генерация)
  |
  v
S8: Выбор наполнения (клетка/линейка/точки/пустые)
  |
  v
S9: Выбор уровня (Core / Signature / Lux)
  - Каталожные дизайны: 3 разных превью (tier_modifiers)
  - Генерации: 1 превью + мокапы с отделкой
  - Limited: badge "Лимитированный тираж: X/N осталось"
  |
  v
Backend: создание Order (draft) + OrderItem
  - tier = выбранный уровень
  - notebook_sku_id = NotebookSku по tier
  - collection_id = если из коллекции
  - drop_id (через EditionAssignment) = если из дропа
  - Проверка stock (если limited)
  |
  v
S10: Оформление заказа (контакты, доставка, инициалы для Signature/Lux)
  - Order.status -> "awaiting_payment"
  |
  v
S11: Оплата (YooKassa redirect)
  |
  v
Webhook: Payment.status -> "succeeded"
  - Order.status -> "paid"
  - Assign edition (если limited, с pessimistic locking)
  - Генерация order_number + barcode
  - Запуск OrderFileGenerationJob (tier-aware)
  |
  v
S12: Заказ принят (номер + QR + edition info)
```

## 11. Обработка ошибок

### 11.1. Stock exhausted между checkout и оплатой

```
Сценарий: пользователь начал оплату, но за это время
           last edition купил другой пользователь.

1. Webhook приходит: Payment.status -> "succeeded"
2. assign_edition! выбрасывает OutOfStockError
3. Автоматический refund через YooKassa API
4. Order.status -> "refunded"
5. Email пользователю: "Тираж закончился, возврат оформлен"
6. Лог в admin: "Auto-refund: stock exhausted"
```

### 11.2. Webhook идемпотентность

```ruby
# Псевдокод
def process_webhook(payload)
  payment = Payment.find_by(provider_payment_id: payload["id"])
  return if payment.nil?

  # Идемпотентность: не обрабатываем повторный webhook с тем же статусом
  return if payment.status == payload["status"]

  # Проверка допустимого перехода
  return unless valid_transition?(payment.status, payload["status"])

  payment.update!(
    status: payload["status"],
    raw: payload,
    captured_at: payload["captured_at"]
  )

  # Side effects
  case payload["status"]
  when "succeeded"
    payment.payable.mark_as_paid!
  when "canceled", "failed"
    payment.payable.mark_as_canceled! if payment.payable.is_a?(Order)
  end
end
```

### 11.3. Ошибки генерации файлов

Если `OrderFileGenerationJob` упал:
- order_files.status -> "failed"
- Retry через Sidekiq (3 попытки)
- После 3 неудач — уведомление админу
- Заказ остается в `"paid"` (файлы можно перегенерировать вручную)
