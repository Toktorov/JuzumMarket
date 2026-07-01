import random
from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth.hashers import make_password, check_password
from django.db.models import Q
from rest_framework import viewsets, mixins, status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import Category, Product, Customer, Order, Review, Notification
from .utils import normalize_phone
from .serializers import (
    CategorySerializer, ProductSerializer, OrderCreateSerializer,
    OrderReadSerializer, CustomerSerializer, ReviewSerializer,
    ReviewCreateSerializer, ReplyCreateSerializer, NotificationSerializer,
)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CategorySerializer
    # products_count читается из свойства модели (см. Category.products_count).
    queryset = Category.objects.filter(is_active=True)


class ProductViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ProductSerializer

    def get_queryset(self):
        qs = (Product.objects.filter(is_active=True)
              .select_related('category').prefetch_related('options'))
        category = self.request.query_params.get('category')
        search = self.request.query_params.get('search')
        exclude = self.request.query_params.get('exclude')
        if category:
            # Категория может прийти на любом языке.
            qs = qs.filter(
                Q(category__name=category) |
                Q(category__name_ky=category) |
                Q(category__name_en=category))
        if search:
            qs = qs.filter(
                Q(name__icontains=search) |
                Q(name_ky__icontains=search) |
                Q(name_en__icontains=search))
        if exclude:
            qs = qs.exclude(pk=exclude)
        return qs


class OrderViewSet(mixins.CreateModelMixin,
                   mixins.RetrieveModelMixin,
                   mixins.ListModelMixin,
                   viewsets.GenericViewSet):
    queryset = Order.objects.prefetch_related('items').all()

    def get_serializer_class(self):
        if self.action == 'create':
            return OrderCreateSerializer
        return OrderReadSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        phone = self.request.query_params.get('phone')
        if phone:
            qs = qs.filter(customer__phone=normalize_phone(phone))
        return qs


class ReviewViewSet(mixins.CreateModelMixin,
                    mixins.ListModelMixin,
                    viewsets.GenericViewSet):
    queryset = Review.objects.prefetch_related('replies').all()

    def get_serializer_class(self):
        return ReviewCreateSerializer if self.action == 'create' \
            else ReviewSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        product = self.request.query_params.get('product')
        if product:
            qs = qs.filter(product_id=product)
        return qs


class NotificationViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        phone = normalize_phone(self.request.query_params.get('phone') or '')
        if not phone:
            return Notification.objects.none()
        return (Notification.objects.select_related('product')
                .filter(customer__phone=phone))


@api_view(['POST'])
def notifications_read_view(request):
    """Отмечает уведомления прочитанными (одно по id или все)."""
    phone = normalize_phone(request.data.get('phone') or '')
    qs = Notification.objects.filter(customer__phone=phone)
    nid = request.data.get('id')
    if nid:
        qs = qs.filter(id=nid)
    updated = qs.update(is_read=True)
    return Response({'updated': updated})


@api_view(['POST'])
def reply_view(request):
    """Создать ответ на отзыв."""
    serializer = ReplyCreateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    reply = serializer.save()
    return Response(serializer.to_representation(reply),
                    status=status.HTTP_201_CREATED)


def _bad(msg):
    return Response({'detail': msg}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def register_view(request):
    """Регистрация: номер + имя + пароль."""
    phone = normalize_phone(request.data.get('phone') or '')
    name = (request.data.get('name') or '').strip()
    password = request.data.get('password') or ''
    if len(phone) < 8:
        return _bad('Введите корректный номер')
    if len(password) < 4:
        return _bad('Пароль должен быть не короче 4 символов')

    existing = Customer.objects.filter(phone=phone).first()
    if existing and existing.password:
        return _bad('Этот номер уже зарегистрирован. Войдите.')

    email = (request.data.get('email') or '').strip()
    customer = existing or Customer(phone=phone)
    if name:
        customer.name = name
    if email:
        customer.email = email
    customer.password = make_password(password)
    customer.save()
    return Response(CustomerSerializer(customer).data,
                    status=status.HTTP_201_CREATED)


@api_view(['POST'])
def login_view(request):
    """Вход: номер + пароль."""
    phone = normalize_phone(request.data.get('phone') or '')
    password = request.data.get('password') or ''
    if len(phone) < 8:
        return _bad('Введите корректный номер')

    customer = Customer.objects.filter(phone=phone).first()
    if customer is None:
        return _bad('Аккаунт не найден. Зарегистрируйтесь.')

    if not customer.password:
        # Старый аккаунт без пароля — задаём введённый как пароль.
        customer.password = make_password(password)
        customer.save(update_fields=['password'])
    elif not check_password(password, customer.password):
        return _bad('Неверный пароль')

    return Response(CustomerSerializer(customer).data)


@api_view(['POST'])
def subscribe_premium_view(request):
    """Разовая покупка Premium (навсегда). Активирует статус бессрочно."""
    phone = normalize_phone(request.data.get('phone') or '')
    if len(phone) < 8:
        return _bad('Введите корректный номер')
    customer = Customer.objects.filter(phone=phone).first()
    if customer is None:
        return _bad('Аккаунт не найден. Войдите, чтобы оформить Premium.')

    if customer.premium_active:
        return _bad('Premium уже активен.')

    customer.grant_premium_lifetime()
    Notification.objects.create(
        customer=customer,
        kind=Notification.Kind.PROMO,
        title='Добро пожаловать в JUZUM Premium ★',
        body='Premium активирован навсегда. Теперь вам доступны специальные '
             'цены на товары по всему каталогу. Приятных покупок!',
    )
    return Response(CustomerSerializer(customer).data)


@api_view(['POST'])
def profile_update_view(request):
    """Обновление имени и email покупателя (по телефону)."""
    phone = normalize_phone(request.data.get('phone') or '')
    name = (request.data.get('name') or '').strip()
    email = request.data.get('email')
    customer = Customer.objects.filter(phone=phone).first()
    if customer is None:
        return _bad('Аккаунт не найден')
    fields = []
    if name:
        customer.name = name
        fields.append('name')
    if email is not None:
        customer.email = email.strip()
        fields.append('email')
    if fields:
        customer.save(update_fields=fields)
    return Response(CustomerSerializer(customer).data)


@api_view(['POST'])
def forgot_password_view(request):
    """Отправляет 6-значный код сброса на email покупателя."""
    email = (request.data.get('email') or '').strip()
    if not email:
        return _bad('Введите email')
    customer = Customer.objects.filter(email__iexact=email).first()
    if customer is None:
        return _bad('Аккаунт с такой почтой не найден')

    code = f'{random.randint(0, 999999):06d}'
    customer.reset_code = code
    customer.reset_code_at = timezone.now()
    customer.save(update_fields=['reset_code', 'reset_code_at'])

    try:
        send_mail(
            'Код для сброса пароля JUZUM',
            f'Здравствуйте!\n\nВаш код для сброса пароля: {code}\n\n'
            f'Код действует {settings.PASSWORD_RESET_CODE_TTL_MINUTES} минут.\n'
            f'Если вы не запрашивали сброс — просто игнорируйте это письмо.\n\n'
            f'— Команда JUZUM',
            None,
            [email],
            fail_silently=False,
        )
    except Exception:
        return Response(
            {'detail': 'Не удалось отправить письмо. Попробуйте позже.'},
            status=status.HTTP_502_BAD_GATEWAY)

    return Response({'ok': True})


@api_view(['POST'])
def reset_password_view(request):
    """Сбрасывает пароль по коду из письма."""
    email = (request.data.get('email') or '').strip()
    code = (request.data.get('code') or '').strip()
    password = request.data.get('password') or ''
    if len(password) < 4:
        return _bad('Пароль должен быть не короче 4 символов')

    customer = Customer.objects.filter(email__iexact=email).first()
    if customer is None or not customer.reset_code:
        return _bad('Сначала запросите код сброса')
    if customer.reset_code != code:
        return _bad('Неверный код')

    ttl = timedelta(minutes=settings.PASSWORD_RESET_CODE_TTL_MINUTES)
    if customer.reset_code_at and timezone.now() - customer.reset_code_at > ttl:
        return _bad('Код истёк. Запросите новый.')

    customer.password = make_password(password)
    customer.reset_code = ''
    customer.reset_code_at = None
    customer.save(update_fields=['password', 'reset_code', 'reset_code_at'])
    return Response({'ok': True})
