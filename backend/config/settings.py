"""
Django settings for JUZUM backend.
Marketplace backend: catalog, customers, orders + branded admin + REST API.
"""
import os
from pathlib import Path
from django.urls import reverse_lazy
from django.templatetags.static import static

BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY: для разработки. На проде вынести в переменные окружения.
SECRET_KEY = 'django-insecure-juzum-dev-key-change-me-in-production'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    # Современная тема админки Unfold — строго ДО django.contrib.admin.
    'unfold',
    'unfold.contrib.filters',
    'unfold.contrib.forms',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Сторонние
    'rest_framework',
    'corsheaders',
    # Наше
    'shop',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
]

LANGUAGE_CODE = 'ru'
TIME_ZONE = 'Asia/Bishkek'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- REST API ---
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.AllowAny'],
    'DEFAULT_PAGINATION_CLASS':
        'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,
}

# Разрешаем приложению (Flutter) обращаться к API во время разработки.
CORS_ALLOW_ALL_ORIGINS = True

# --- Почта (Gmail SMTP) для сброса пароля ---
# Логин и «пароль приложения» Gmail берутся из переменных окружения:
#   JUZUM_EMAIL_USER=твоя_почта@gmail.com
#   JUZUM_EMAIL_PASS=пароль-приложения-16-символов
EMAIL_HOST_USER = os.environ.get('JUZUM_EMAIL_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('JUZUM_EMAIL_PASS', '')
if EMAIL_HOST_USER and EMAIL_HOST_PASSWORD:
    EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
    EMAIL_HOST = 'smtp.gmail.com'
    EMAIL_PORT = 587
    EMAIL_USE_TLS = True
else:
    # Нет данных Gmail — письма печатаются в консоль сервера.
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
DEFAULT_FROM_EMAIL = f'JUZUM <{EMAIL_HOST_USER or "no-reply@juzum.kg"}>'
PASSWORD_RESET_CODE_TTL_MINUTES = 15

# --- Современная админка Unfold (фирменный фиолетовый JUZUM) ---
UNFOLD = {
    'SITE_TITLE': 'JUZUM Admin',
    'SITE_HEADER': 'JUZUM',
    'SITE_SUBHEADER': 'Панель управления магазином',
    'SITE_SYMBOL': 'storefront',
    'SHOW_HISTORY': True,
    # Боковое меню по умолчанию открыто (можно закрыть кнопкой).
    'SCRIPTS': [lambda request: static('admin/js/sidebar_default.js')],
    'SHOW_VIEW_ON_SITE': False,
    'COLORS': {
        'primary': {
            '50': '245 243 255',
            '100': '237 233 254',
            '200': '221 214 254',
            '300': '196 181 253',
            '400': '167 139 250',
            '500': '139 92 246',
            '600': '122 24 224',
            '700': '109 40 217',
            '800': '91 33 182',
            '900': '76 29 149',
            '950': '46 16 101',
        },
    },
    'SIDEBAR': {
        'show_search': True,
        'show_all_applications': False,
        'navigation': [
            {
                'title': 'Каталог',
                'separator': True,
                'items': [
                    {'title': 'Товары', 'icon': 'inventory_2',
                     'link': reverse_lazy('admin:shop_product_changelist')},
                    {'title': 'Категории', 'icon': 'category',
                     'link': reverse_lazy('admin:shop_category_changelist')},
                ],
            },
            {
                'title': 'Продажи',
                'separator': True,
                'items': [
                    {'title': 'Заказы', 'icon': 'receipt_long',
                     'link': reverse_lazy('admin:shop_order_changelist')},
                    {'title': 'Отчёт по продажам', 'icon': 'analytics',
                     'link': reverse_lazy('admin:sales_report')},
                    {'title': 'Покупатели', 'icon': 'group',
                     'link': reverse_lazy('admin:shop_customer_changelist')},
                ],
            },
            {
                'title': 'Контент',
                'separator': True,
                'items': [
                    {'title': 'Отзывы', 'icon': 'reviews',
                     'link': reverse_lazy('admin:shop_review_changelist')},
                    {'title': 'Избранное', 'icon': 'favorite',
                     'link': reverse_lazy('admin:shop_favorite_changelist')},
                ],
            },
            {
                'title': 'Система',
                'separator': True,
                'items': [
                    {'title': 'Администраторы', 'icon': 'shield_person',
                     'link': reverse_lazy('admin:auth_user_changelist')},
                ],
            },
        ],
    },
}
