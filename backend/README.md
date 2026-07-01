# JUZUM — backend

Django-бэкенд маркетплейса JUZUM: каталог, покупатели, заказы + REST API + брендированная админка (Jazzmin).

## Запуск

```bash
cd backend
source venv/bin/activate          # или ./venv/bin/python вместо python ниже
python manage.py migrate
python manage.py seed             # наполнить каталог (16 товаров, 5 категорий)
python manage.py runserver        # http://127.0.0.1:8000
```

Чтобы приложение с телефона могло достучаться — запускать на всю сеть:
```bash
python manage.py runserver 0.0.0.0:8000
```
и обращаться по IP компьютера в локальной сети (напр. http://192.168.0.10:8000).

## Админка

- URL: http://127.0.0.1:8000/admin/
- Логин: **admin** · Пароль: **admin123** (создан для разработки — поменять позже)
- Разделы: Товары, Категории, Заказы, Покупатели, Избранное.
- Заказы: цветные статусы, позиции внутри заказа, авто-итоги, оплата.
- Товары: превью фото, быстрое редактирование цены/наличия прямо в списке.

## REST API (префикс `/api/`)

| Метод | Путь | Назначение |
|---|---|---|
| GET | `/api/categories/` | список категорий (с числом товаров и иконкой) |
| GET | `/api/products/` | список товаров; фильтры `?category=Электроника`, `?search=...` |
| GET | `/api/products/{id}/` | один товар |
| POST | `/api/auth/login/` | вход по телефону `{phone, name}` → покупатель |
| POST | `/api/orders/` | создать заказ (см. ниже) |
| GET | `/api/orders/?phone=+996...` | заказы покупателя |
| GET | `/api/orders/{id}/` | один заказ |

### Создание заказа

```json
POST /api/orders/
{
  "phone": "+996700112233",
  "name": "Айгуль",
  "delivery_name": "Айгуль",
  "delivery_phone": "+996700112233",
  "city": "Бишкек",
  "address": "ул. Чуй 1",
  "comment": "",
  "payment": "online",          // online | cash
  "items": [{"product": 1, "quantity": 2}, {"product": 7, "quantity": 1}]
}
```

Сервер сам считает доставку (150 сом, бесплатно от 3000), фиксирует цены/названия
позиций на момент заказа, для онлайн-оплаты ставит `is_paid = true` и присваивает
номер вида `JZ-1001`.

## Технологии
Django 5.2 · DRF · django-jazzmin · django-cors-headers · Pillow · SQLite (dev).
