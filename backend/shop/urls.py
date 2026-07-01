from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register('categories', views.CategoryViewSet, basename='category')
router.register('products', views.ProductViewSet, basename='product')
router.register('orders', views.OrderViewSet, basename='order')
router.register('reviews', views.ReviewViewSet, basename='review')
router.register('notifications', views.NotificationViewSet,
                basename='notification')

urlpatterns = [
    path('notifications/read/', views.notifications_read_view,
         name='notifications-read'),
    path('reviews/reply/', views.reply_view, name='review-reply'),
    path('auth/register/', views.register_view, name='register'),
    path('auth/login/', views.login_view, name='login'),
    path('auth/forgot/', views.forgot_password_view, name='forgot'),
    path('auth/reset/', views.reset_password_view, name='reset'),
    path('auth/premium/', views.subscribe_premium_view, name='premium'),
    path('profile/', views.profile_update_view, name='profile-update'),
    path('', include(router.urls)),
]
