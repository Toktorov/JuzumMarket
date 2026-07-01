from datetime import timedelta
from django.db import models
from django.utils import timezone


def _pick(lang, ru, ky, en):
    """Возвращает перевод для языка с фолбэком на русский."""
    if lang == 'ky' and ky:
        return ky
    if lang == 'en' and en:
        return en
    return ru


class Category(models.Model):
    name = models.CharField('Название', max_length=80, unique=True)
    name_ky = models.CharField('Название (кыргызча)', max_length=80,
                               blank=True)
    name_en = models.CharField('Название (English)', max_length=80,
                               blank=True)
    icon = models.CharField(
        'Иконка (Material)', max_length=40, blank=True,
        help_text='Имя иконки во Flutter, напр. devices_other_rounded',
    )
    order = models.PositiveIntegerField('Порядок', default=0)
    is_active = models.BooleanField('Активна', default=True)

    class Meta:
        verbose_name = 'Категория'
        verbose_name_plural = 'Категории'
        ordering = ['order', 'name']

    def __str__(self):
        return self.name

    def tr_name(self, lang):
        return _pick(lang, self.name, self.name_ky, self.name_en)

    @property
    def products_count(self):
        return self.products.count()


class Product(models.Model):
    name = models.CharField('Название', max_length=160)
    name_ky = models.CharField('Название (кыргызча)', max_length=160,
                               blank=True)
    name_en = models.CharField('Название (English)', max_length=160,
                               blank=True)
    category = models.ForeignKey(
        Category, on_delete=models.PROTECT,
        related_name='products', verbose_name='Категория',
    )
    price = models.DecimalField('Цена, сом', max_digits=10, decimal_places=2)
    cost_price = models.DecimalField(
        'Себестоимость, сом', max_digits=10, decimal_places=2, default=0,
        help_text='Закупочная цена — используется для расчёта прибыли.',
    )
    old_price = models.DecimalField(
        'Старая цена, сом', max_digits=10, decimal_places=2,
        null=True, blank=True,
        help_text='Если заполнено и больше текущей — показывается скидка.',
    )
    premium_price = models.DecimalField(
        'Цена для Premium, сом', max_digits=10, decimal_places=2,
        null=True, blank=True,
        help_text='Сниженная цена для премиум-покупателей. '
                  'Если пусто — премиум платит обычную цену.',
    )
    description = models.TextField('Описание', blank=True)
    description_ky = models.TextField('Описание (кыргызча)', blank=True)
    description_en = models.TextField('Описание (English)', blank=True)

    # Фото: либо загруженное, либо ссылка (пока используются дефолтные ссылки).
    image = models.ImageField(
        'Фото (загрузка)', upload_to='products/', blank=True, null=True,
    )
    image_url = models.URLField('Фото (ссылка)', blank=True, max_length=500)

    is_active = models.BooleanField('В продаже', default=True)
    in_stock = models.BooleanField('В наличии', default=True)
    created_at = models.DateTimeField('Создан', auto_now_add=True)
    updated_at = models.DateTimeField('Обновлён', auto_now=True)

    class Meta:
        verbose_name = 'Товар'
        verbose_name_plural = 'Товары'
        ordering = ['-created_at']

    def __str__(self):
        return self.name

    def tr_name(self, lang):
        return _pick(lang, self.name, self.name_ky, self.name_en)

    def tr_description(self, lang):
        return _pick(lang, self.description,
                     self.description_ky, self.description_en)

    @property
    def photo(self):
        """Итоговый адрес фото: загруженное приоритетнее ссылки."""
        if self.image:
            return self.image.url
        return self.image_url

    @property
    def discount_percent(self):
        if self.old_price and self.old_price > self.price:
            return round((1 - self.price / self.old_price) * 100)
        return 0

    @property
    def premium_discount_percent(self):
        """Насколько премиум-цена ниже обычной (в %)."""
        if self.premium_price and self.premium_price < self.price:
            return round((1 - self.premium_price / self.price) * 100)
        return 0

    def price_for(self, customer):
        """Цена для конкретного покупателя: премиум платит premium_price."""
        if (customer is not None and customer.premium_active
                and self.premium_price and self.premium_price < self.price):
            return self.premium_price
        return self.price

    @property
    def avg_rating(self):
        agg = self.reviews.aggregate(models.Avg('rating'))
        return round(agg['rating__avg'] or 0, 1)

    @property
    def reviews_count(self):
        return self.reviews.count()


class ProductOption(models.Model):
    """Вариант товара: группа (Цвет/Модель/…) + значение + надбавка к цене."""
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name='options',
        verbose_name='Товар',
    )
    group = models.CharField(
        'Что выбирают', max_length=40,
        help_text='Тип выбора: «Цвет», «Размер» или «Модель».',
    )
    value = models.CharField(
        'Вариант', max_length=80,
        help_text='Например: «Чёрный», «Белый», «M», «Pro».')
    price_delta = models.DecimalField(
        'Доплата, сом', max_digits=10, decimal_places=2, default=0,
        help_text='На сколько этот вариант дороже обычной цены. '
                  '0 — та же цена. Например 200 — на 200 сом дороже.',
    )
    # Фото варианта (напр. футболка в этом цвете). Загрузка важнее ссылки.
    image = models.ImageField(
        'Фото варианта', upload_to='options/', blank=True, null=True,
        help_text='Загрузите фото товара в этом варианте (для цвета — '
                  'фото в этом цвете). Покупатель листает эти фото.')
    image_url = models.URLField(
        'Фото по ссылке', blank=True, max_length=500,
        help_text='Необязательно. Если проще вставить ссылку на фото.')
    order = models.PositiveIntegerField(
        'Порядок', default=0,
        help_text='Порядок показа (0, 1, 2…). Можно оставить 0.')
    is_active = models.BooleanField('Показывать', default=True)

    class Meta:
        verbose_name = 'Вариант товара'
        verbose_name_plural = 'Варианты товара'
        ordering = ['group', 'order', 'id']

    def __str__(self):
        return f'{self.group}: {self.value}'

    @property
    def photo(self):
        if self.image:
            return self.image.url
        return self.image_url


class Customer(models.Model):
    """Покупатель приложения (вход по номеру телефона + паролю)."""
    phone = models.CharField('Телефон', max_length=32, unique=True)
    name = models.CharField('Имя', max_length=120, blank=True)
    email = models.EmailField('Email', blank=True)
    password = models.CharField('Пароль (хеш)', max_length=255, blank=True)
    is_premium = models.BooleanField('Premium-подписка', default=False)
    premium_until = models.DateTimeField(
        'Premium активен до', null=True, blank=True,
        help_text='Пусто при включённой подписке = бессрочный премиум.',
    )
    reset_code = models.CharField('Код сброса', max_length=6, blank=True)
    reset_code_at = models.DateTimeField('Код запрошен', null=True, blank=True)
    created_at = models.DateTimeField('Регистрация', auto_now_add=True)

    class Meta:
        verbose_name = 'Покупатель'
        verbose_name_plural = 'Покупатели'
        ordering = ['-created_at']

    def __str__(self):
        mark = ' ★Premium' if self.premium_active else ''
        return f'{self.name or "Без имени"} · {self.phone}{mark}'

    @property
    def orders_count(self):
        return self.orders.count()

    @property
    def premium_active(self):
        """Активна ли премиум-подписка прямо сейчас."""
        if not self.is_premium:
            return False
        if self.premium_until and self.premium_until < timezone.now():
            return False
        return True

    def grant_premium(self, days=30):
        """Включает/продлевает премиум на `days` дней от текущего срока."""
        base = self.premium_until
        if not base or base < timezone.now():
            base = timezone.now()
        self.is_premium = True
        self.premium_until = base + timedelta(days=days)
        self.save(update_fields=['is_premium', 'premium_until'])
        return self

    def grant_premium_lifetime(self):
        """Разовая покупка: премиум навсегда (без срока действия)."""
        self.is_premium = True
        self.premium_until = None
        self.save(update_fields=['is_premium', 'premium_until'])
        return self


class Order(models.Model):
    class Status(models.TextChoices):
        PROCESSING = 'processing', 'В обработке'
        CONFIRMED = 'confirmed', 'Подтверждён'
        DELIVERING = 'delivering', 'В доставке'
        DELIVERED = 'delivered', 'Доставлен'
        CANCELLED = 'cancelled', 'Отменён'

    class Payment(models.TextChoices):
        ONLINE = 'online', 'Онлайн-оплата картой'
        CASH = 'cash', 'Наличными при получении'

    number = models.CharField('Номер заказа', max_length=20, unique=True,
                              blank=True)
    customer = models.ForeignKey(
        Customer, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='orders', verbose_name='Покупатель',
    )

    # Данные доставки
    delivery_name = models.CharField('Имя получателя', max_length=120)
    delivery_phone = models.CharField('Телефон', max_length=32)
    city = models.CharField('Город', max_length=80)
    address = models.CharField('Адрес', max_length=255)
    comment = models.TextField('Комментарий', blank=True)

    payment = models.CharField(
        'Оплата', max_length=10, choices=Payment.choices,
        default=Payment.ONLINE,
    )
    is_paid = models.BooleanField('Оплачен', default=False)
    status = models.CharField(
        'Статус', max_length=12, choices=Status.choices,
        default=Status.PROCESSING,
    )

    delivery_fee = models.DecimalField(
        'Доставка, сом', max_digits=10, decimal_places=2, default=0,
    )
    created_at = models.DateTimeField('Создан', auto_now_add=True)

    class Meta:
        verbose_name = 'Заказ'
        verbose_name_plural = 'Заказы'
        ordering = ['-created_at']

    def __str__(self):
        return self.number or f'Заказ #{self.pk}'

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.number:
            # Номер вида JZ-1001 на основе первичного ключа.
            Order.objects.filter(pk=self.pk).update(
                number=f'JZ-{1000 + self.pk}')
            self.number = f'JZ-{1000 + self.pk}'

    @property
    def items_total(self):
        return sum((i.total for i in self.items.all()), 0)

    @property
    def grand_total(self):
        return self.items_total + self.delivery_fee

    @property
    def items_count(self):
        return sum(i.quantity for i in self.items.all())


class OrderItem(models.Model):
    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, related_name='items',
        verbose_name='Заказ',
    )
    product = models.ForeignKey(
        Product, on_delete=models.SET_NULL, null=True,
        verbose_name='Товар',
    )
    # Снимок на момент заказа (чтобы не «поплыло» при смене цены/имени).
    product_name = models.CharField('Название', max_length=160)
    price = models.DecimalField('Цена, сом', max_digits=10, decimal_places=2)
    cost = models.DecimalField(
        'Себестоимость, сом', max_digits=10, decimal_places=2, default=0,
        help_text='Снимок закупочной цены на момент заказа.',
    )
    options = models.CharField(
        'Выбранные варианты', max_length=255, blank=True,
        help_text='Напр. «Цвет: Чёрный · Модель: Pro».',
    )
    image_url = models.CharField(
        'Фото (снимок)', max_length=500, blank=True,
        help_text='Фото выбранного варианта на момент заказа.',
    )
    quantity = models.PositiveIntegerField('Количество', default=1)

    class Meta:
        verbose_name = 'Позиция заказа'
        verbose_name_plural = 'Позиции заказа'

    def __str__(self):
        return f'{self.product_name} ×{self.quantity}'

    @property
    def total(self):
        return self.price * self.quantity

    @property
    def total_cost(self):
        return self.cost * self.quantity

    @property
    def profit(self):
        return (self.price - self.cost) * self.quantity


class Favorite(models.Model):
    customer = models.ForeignKey(
        Customer, on_delete=models.CASCADE, related_name='favorites',
        verbose_name='Покупатель',
    )
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name='favorited_by',
        verbose_name='Товар',
    )
    created_at = models.DateTimeField('Добавлено', auto_now_add=True)

    class Meta:
        verbose_name = 'Избранное'
        verbose_name_plural = 'Избранное'
        unique_together = ('customer', 'product')

    def __str__(self):
        return f'{self.customer} ♡ {self.product}'


class Notification(models.Model):
    class Kind(models.TextChoices):
        REPLY = 'reply', 'Ответ на отзыв'
        ORDER = 'order', 'Статус заказа'
        DISCOUNT = 'discount', 'Скидка'
        PROMO = 'promo', 'Акция / рассылка'

    customer = models.ForeignKey(
        Customer, on_delete=models.CASCADE, related_name='notifications',
        verbose_name='Покупатель',
    )
    kind = models.CharField('Тип', max_length=12, choices=Kind.choices,
                            default=Kind.PROMO)
    title = models.CharField('Заголовок', max_length=140)
    body = models.TextField('Текст', blank=True)
    product = models.ForeignKey(
        Product, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name='Товар (для перехода)',
    )
    is_read = models.BooleanField('Прочитано', default=False)
    created_at = models.DateTimeField('Создано', auto_now_add=True)

    class Meta:
        verbose_name = 'Уведомление'
        verbose_name_plural = 'Уведомления'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.get_kind_display()} → {self.customer}'


class Broadcast(models.Model):
    """Рассылка из админки: создаёт уведомления выбранной аудитории."""
    class Audience(models.TextChoices):
        ALL = 'all', 'Все покупатели'
        FAVORITED = 'favorited', 'Те, у кого товар в избранном'

    title = models.CharField('Заголовок', max_length=140)
    body = models.TextField('Текст', blank=True)
    audience = models.CharField('Кому', max_length=12,
                                choices=Audience.choices,
                                default=Audience.ALL)
    product = models.ForeignKey(
        Product, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name='Товар',
        help_text='Для «в избранном» и для перехода по уведомлению.',
    )
    sent = models.BooleanField('Отправлено', default=False)
    sent_count = models.PositiveIntegerField('Получателей', default=0)
    created_at = models.DateTimeField('Создано', auto_now_add=True)

    class Meta:
        verbose_name = 'Рассылка'
        verbose_name_plural = 'Рассылки'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    def send(self):
        if self.sent:
            return 0
        if self.audience == self.Audience.FAVORITED and self.product:
            customers = Customer.objects.filter(
                favorites__product=self.product).distinct()
        else:
            customers = Customer.objects.all()
        notifications = [
            Notification(customer=c, kind=Notification.Kind.PROMO,
                         title=self.title, body=self.body, product=self.product)
            for c in customers
        ]
        Notification.objects.bulk_create(notifications)
        self.sent = True
        self.sent_count = len(notifications)
        self.save(update_fields=['sent', 'sent_count'])
        return self.sent_count


class Review(models.Model):
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name='reviews',
        verbose_name='Товар',
    )
    customer = models.ForeignKey(
        Customer, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='reviews', verbose_name='Покупатель',
    )
    author_name = models.CharField('Имя автора', max_length=120, blank=True)
    rating = models.PositiveSmallIntegerField('Оценка (1–5)', default=5)
    text = models.TextField('Текст отзыва', blank=True)
    created_at = models.DateTimeField('Создан', auto_now_add=True)

    class Meta:
        verbose_name = 'Отзыв'
        verbose_name_plural = 'Отзывы'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.author_name or "Аноним"} · {self.rating}★ · {self.product}'


class ReviewReply(models.Model):
    review = models.ForeignKey(
        Review, on_delete=models.CASCADE, related_name='replies',
        verbose_name='Отзыв',
    )
    customer = models.ForeignKey(
        Customer, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='replies', verbose_name='Покупатель',
    )
    author_name = models.CharField('Имя автора', max_length=120, blank=True)
    is_seller = models.BooleanField('Ответ магазина', default=False)
    text = models.TextField('Текст ответа')
    created_at = models.DateTimeField('Создан', auto_now_add=True)

    class Meta:
        verbose_name = 'Ответ на отзыв'
        verbose_name_plural = 'Ответы на отзывы'
        ordering = ['created_at']

    def __str__(self):
        return f'Ответ на отзыв #{self.review_id}'
