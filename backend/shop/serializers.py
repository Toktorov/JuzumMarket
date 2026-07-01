from decimal import Decimal
from rest_framework import serializers
from .models import (
    Category, Product, Customer, Order, OrderItem, Review, ReviewReply,
    Notification, ProductOption,
)
from .utils import normalize_phone


def _lang_from(context):
    request = context.get('request')
    if request is not None:
        return request.query_params.get('lang') or 'ru'
    return 'ru'


class CategorySerializer(serializers.ModelSerializer):
    products_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Category
        # Отдаём все языки сразу — приложение переключает мгновенно.
        fields = ('id', 'name', 'name_ky', 'name_en', 'icon',
                  'products_count')


class ProductSerializer(serializers.ModelSerializer):
    # Все языки сразу (name = русский). Приложение выбирает нужный локально.
    category = serializers.CharField(source='category.name', read_only=True)
    category_ky = serializers.CharField(source='category.name_ky',
                                        read_only=True)
    category_en = serializers.CharField(source='category.name_en',
                                        read_only=True)
    category_id = serializers.IntegerField(source='category.id', read_only=True)
    price = serializers.FloatField()
    old_price = serializers.FloatField(allow_null=True)
    premium_price = serializers.FloatField(allow_null=True)
    premium_discount_percent = serializers.IntegerField(read_only=True)
    discount_percent = serializers.IntegerField(read_only=True)
    rating = serializers.FloatField(source='avg_rating', read_only=True)
    reviews_count = serializers.IntegerField(read_only=True)
    photo = serializers.SerializerMethodField()
    option_groups = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'name_ky', 'name_en',
            'category', 'category_ky', 'category_en', 'category_id',
            'price', 'old_price', 'premium_price', 'premium_discount_percent',
            'discount_percent', 'rating', 'reviews_count',
            'description', 'description_ky', 'description_en',
            'photo', 'is_active', 'in_stock', 'option_groups',
        )

    def get_option_groups(self, obj):
        """Активные варианты, сгруппированные по группе (Цвет, Модель…)."""
        request = self.context.get('request')
        groups = []
        index = {}
        for opt in obj.options.filter(is_active=True):
            if opt.group not in index:
                index[opt.group] = len(groups)
                groups.append({'group': opt.group, 'options': []})
            photo = opt.photo
            if photo and request is not None and photo.startswith('/'):
                photo = request.build_absolute_uri(photo)
            groups[index[opt.group]]['options'].append({
                'id': opt.id,
                'value': opt.value,
                'price_delta': float(opt.price_delta),
                'photo': photo or '',
            })
        return groups

    def get_photo(self, obj):
        request = self.context.get('request')
        photo = obj.photo
        if photo and request is not None and photo.startswith('/'):
            return request.build_absolute_uri(photo)
        return photo


class ReviewReplySerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewReply
        fields = ('id', 'author_name', 'is_seller', 'text', 'created_at')


class ReviewSerializer(serializers.ModelSerializer):
    replies = ReviewReplySerializer(many=True, read_only=True)

    class Meta:
        model = Review
        fields = ('id', 'author_name', 'rating', 'text', 'created_at',
                  'replies')


class ReviewCreateSerializer(serializers.Serializer):
    product = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all())
    phone = serializers.CharField(max_length=32, required=False,
                                  allow_blank=True, default='')
    name = serializers.CharField(max_length=120, required=False,
                                 allow_blank=True, default='')
    rating = serializers.IntegerField(min_value=1, max_value=5)
    text = serializers.CharField(allow_blank=True, required=False, default='')

    def create(self, validated):
        customer = _customer_from(validated)
        return Review.objects.create(
            product=validated['product'],
            customer=customer,
            author_name=validated.get('name') or
            (customer.name if customer else 'Аноним'),
            rating=validated['rating'],
            text=validated.get('text', ''),
        )

    def to_representation(self, instance):
        return ReviewSerializer(instance, context=self.context).data


class ReplyCreateSerializer(serializers.Serializer):
    review = serializers.PrimaryKeyRelatedField(
        queryset=Review.objects.all())
    phone = serializers.CharField(max_length=32, required=False,
                                  allow_blank=True, default='')
    name = serializers.CharField(max_length=120, required=False,
                                 allow_blank=True, default='')
    text = serializers.CharField()

    def create(self, validated):
        customer = _customer_from(validated)
        review = validated['review']
        reply = ReviewReply.objects.create(
            review=review,
            customer=customer,
            author_name=validated.get('name') or
            (customer.name if customer else 'Аноним'),
            text=validated['text'],
        )
        # Уведомление автору отзыва (если отвечает кто-то другой).
        if review.customer and review.customer != customer:
            Notification.objects.create(
                customer=review.customer,
                kind=Notification.Kind.REPLY,
                title='Вам ответили на отзыв',
                body=f'{reply.author_name}: {reply.text[:90]}',
                product=review.product,
            )
        return reply

    def to_representation(self, instance):
        return ReviewReplySerializer(instance, context=self.context).data


class NotificationSerializer(serializers.ModelSerializer):
    kind_display = serializers.CharField(
        source='get_kind_display', read_only=True)
    product_id = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ('id', 'kind', 'kind_display', 'title', 'body',
                  'product_id', 'is_read', 'created_at')

    def get_product_id(self, obj):
        return str(obj.product_id) if obj.product_id else None


def _customer_from(validated):
    phone = normalize_phone(validated.get('phone') or '')
    if not phone:
        return None
    customer, _ = Customer.objects.get_or_create(
        phone=phone, defaults={'name': validated.get('name', '')})
    return customer


class OrderItemSerializer(serializers.ModelSerializer):
    total = serializers.FloatField(read_only=True)
    price = serializers.FloatField()
    photo = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = ('product', 'product_name', 'price', 'quantity', 'total',
                  'options', 'photo')

    def get_photo(self, obj):
        photo = obj.image_url
        request = self.context.get('request')
        if photo and request is not None and photo.startswith('/'):
            return request.build_absolute_uri(photo)
        return photo or ''


class OrderItemInputSerializer(serializers.Serializer):
    product = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all())
    quantity = serializers.IntegerField(min_value=1, default=1)
    # id выбранных вариантов (ProductOption). Необязательно.
    options = serializers.ListField(
        child=serializers.IntegerField(), required=False, default=list)


class OrderReadSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    status_display = serializers.CharField(
        source='get_status_display', read_only=True)
    payment_display = serializers.CharField(
        source='get_payment_display', read_only=True)
    items_total = serializers.FloatField(read_only=True)
    grand_total = serializers.FloatField(read_only=True)
    delivery_fee = serializers.FloatField()

    class Meta:
        model = Order
        fields = (
            'id', 'number', 'status', 'status_display', 'payment',
            'payment_display', 'is_paid', 'delivery_name', 'delivery_phone',
            'city', 'address', 'comment', 'delivery_fee', 'items_total',
            'grand_total', 'items', 'created_at',
        )


class OrderCreateSerializer(serializers.Serializer):
    """Создание заказа из приложения."""
    DELIVERY_FEE = Decimal('150')
    FREE_FROM = Decimal('3000')

    # покупатель
    phone = serializers.CharField(max_length=32)
    name = serializers.CharField(max_length=120, allow_blank=True,
                                 required=False, default='')

    # доставка
    delivery_name = serializers.CharField(max_length=120)
    delivery_phone = serializers.CharField(max_length=32)
    city = serializers.CharField(max_length=80)
    address = serializers.CharField(max_length=255)
    comment = serializers.CharField(allow_blank=True, required=False,
                                    default='')

    payment = serializers.ChoiceField(choices=Order.Payment.choices)
    items = OrderItemInputSerializer(many=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError('Корзина пуста')
        return value

    def create(self, validated):
        items = validated.pop('items')

        customer, _ = Customer.objects.get_or_create(
            phone=normalize_phone(validated['phone']),
            defaults={'name': validated.get('name', '')},
        )
        if validated.get('name') and customer.name != validated['name']:
            customer.name = validated['name']
            customer.save(update_fields=['name'])

        # Премиум-покупатель платит premium_price (если задана и ниже),
        # плюс надбавки выбранных вариантов (цвет/модель).
        prices = {}
        options_text = {}
        options_photo = {}
        for i in items:
            base = Decimal(str(i['product'].price_for(customer)))
            opts = list(ProductOption.objects.filter(
                pk__in=i.get('options') or [], product=i['product']))
            delta = sum((o.price_delta for o in opts), Decimal('0'))
            prices[id(i)] = base + delta
            options_text[id(i)] = ' · '.join(
                f'{o.group}: {o.value}' for o in opts)
            # Фото выбранного варианта (цвета), иначе — фото товара.
            chosen = next((o.photo for o in opts if o.photo), '')
            options_photo[id(i)] = chosen or i['product'].photo or ''
        items_total = sum(
            (prices[id(i)] * i['quantity'] for i in items),
            Decimal('0'),
        )
        fee = Decimal('0') if items_total >= self.FREE_FROM else self.DELIVERY_FEE

        order = Order.objects.create(
            customer=customer,
            delivery_name=validated['delivery_name'],
            delivery_phone=validated['delivery_phone'],
            city=validated['city'],
            address=validated['address'],
            comment=validated.get('comment', ''),
            payment=validated['payment'],
            is_paid=(validated['payment'] == Order.Payment.ONLINE),
            delivery_fee=fee,
        )
        for i in items:
            product = i['product']
            OrderItem.objects.create(
                order=order,
                product=product,
                product_name=product.name,
                price=prices[id(i)],
                cost=product.cost_price,
                options=options_text[id(i)],
                image_url=options_photo[id(i)],
                quantity=i['quantity'],
            )
        return order

    def to_representation(self, instance):
        return OrderReadSerializer(instance, context=self.context).data


class CustomerSerializer(serializers.ModelSerializer):
    orders_count = serializers.IntegerField(read_only=True)
    is_premium = serializers.BooleanField(source='premium_active',
                                          read_only=True)

    class Meta:
        model = Customer
        fields = ('id', 'phone', 'name', 'email', 'orders_count',
                  'is_premium', 'premium_until', 'created_at')
