# 07. Заказы и оплата — FORMA

> Версия: v0.1 | Дата: 2026-02-14

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

## 4. Файлы производства

### 4.1. Типы файлов (string enum)

| Тип | Описание | Генерация |
|-----|----------|----------|
| `"cover_print_pdf"` | Обложка для печати | После оплаты, hires -> PDF |
| `"inner_print_pdf"` | Внутренний блок | По filling + settings |
| `"dna_card_pdf"` | DNA Card | Шаблон + данные дизайна |
| `"packing_slip_pdf"` | Лист комплектации | Данные заказа + штрихкод |
| `"preview_pack_zip"` | Пакет превью (для сверки) | Все варианты |

### 4.2. Статусы файлов (string enum)

```
"created"   -> "rendering"  (Sidekiq job запущен)
"rendering" -> "ready"      (файл загружен в S3)
"rendering" -> "failed"     (ошибка генерации)
```

### 4.3. Генерация после оплаты

При переходе заказа в `"paid"`:
1. Запускается Sidekiq job `OrderFileGenerationJob`
2. Генерация: cover_print_pdf, inner_print_pdf, dna_card_pdf
3. Файлы загружаются в ActiveStorage (S3)
4. order_files.status -> "ready"

## 5. Лимиты и монетизация генераций

### 5.1. Лимиты

| Тип пользователя | Лимит | Антиабуз |
|-------------------|-------|----------|
| Гость | 2-5 в сутки (настраивается) | IP + fingerprint |
| Авторизованный | 20-50 в сутки (настраивается) | user_id |
| Безлимит (100 ₽) | Без лимита на период | Rate limit + parallel limit |

### 5.2. Подсчет лимита

- Таблица `usage_counters`: user_id/anonymous_identity_id + period (date)
- Инкремент при каждой генерации
- Проверка перед стартом генерации

### 5.3. Безлимит на период

- **Стоимость:** 100 ₽ (настраивается)
- **Период:** 24 часа (настраивается)
- **Fair Use Policy:**
  - Rate limit: не больше X генераций в минуту
  - Лимит параллельных задач: 1-2 одновременно
- **Оплата:** через YooKassa (payable_type: "GenerationPass")

### 5.4. State Machine: GenerationPass

```
"active"   -> "expired"    (ends_at прошло)
"active"   -> "canceled"   (возврат)
```

### 5.5. Проверка доступа к генерации

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

## 6. Оформление заказа (UX-поток)

### 6.1. Данные формы

| Поле | Обязательное | Валидация |
|------|-------------|-----------|
| customer_name | Да | min 2 символа |
| customer_phone | Да | Формат телефона |
| customer_email | Да | Формат email |
| shipping_method | Если есть доставка | Из списка |
| shipping_address | Если доставка | Структурно (город, улица...) |
| notes | Нет | До 500 символов |

### 6.2. Итоговая сумма

```
subtotal = order_items.sum(total_price_cents)
shipping = shipping_rate(method, address)
total = subtotal + shipping
```

### 6.3. После оплаты

1. Order.status -> "paid"
2. Генерация order_number: `FORMA-{year}-{sequential_6digit}`
3. Генерация barcode_value
4. Запуск генерации файлов производства
5. Показ экрана "Заказ принят" с QR + номером
