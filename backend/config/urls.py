from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include
from django.views.generic import TemplateView

admin.site.site_header = 'JUZUM'
admin.site.site_title = 'JUZUM Admin'
admin.site.index_title = 'Управление магазином'

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('shop.urls')),
    # Политика конфиденциальности (нужна для App Store / Google Play)
    path('privacy/', TemplateView.as_view(template_name='privacy.html'),
         name='privacy'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
