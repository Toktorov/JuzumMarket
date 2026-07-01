from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User, Group
from django.utils.html import format_html
from django.db.models import Count, Sum, F, Q, DecimalField
from django.template.response import TemplateResponse
from django.urls import path
from unfold.admin import ModelAdmin, TabularInline

from .models import (
    Category, Product, Customer, Order, OrderItem, Favorite,
    Review, ReviewReply, Notification, Broadcast, ProductOption,
)

# Убираем лишний раздел «Группы» и переоформляем «Пользователей» в стиле Unfold.
admin.site.unregister(Group)
admin.site.unregister(User)


@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):
    pass


@admin.register(Category)
class CategoryAdmin(ModelAdmin):
    list_display = ('name', 'products_badge', 'icon', 'order', 'is_active')
    list_editable = ('order', 'is_active')
    list_display_links = ('name',)
    search_fields = ('name',)
    list_filter = ('is_active',)
    ordering = ('order', 'name')

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.annotate(_pc=Count('products'))

    @admin.display(description='Товаров', ordering='_pc')
    def products_badge(self, obj):
        return format_html(
            '<span style="background:#F0E7FC;color:#7A18E0;'
            'padding:2px 10px;border-radius:10px;font-weight:600;">{}</span>',
            obj._pc,
        )


class ProductOptionInline(TabularInline):
    model = ProductOption
    extra = 1  # пустая строка, чтобы легко добавить новый вариант
    verbose_name = 'Вариант'
    verbose_name_plural = ('Варианты товара — цвета (с фото), размеры, модели. '
                           'Для цвета загрузите фото: покупатель листает их '
                           'и выбирает.')
    fields = ('preview', 'group', 'value', 'image', 'image_url',
              'price_delta', 'is_active')
    readonly_fields = ('preview',)
    ordering = ('group', 'order')

    @admin.display(description='Фото')
    def preview(self, obj):
        photo = obj.photo if obj and obj.pk else ''
        if photo:
            return format_html(
                '<img src="{}" style="width:56px;height:56px;object-fit:cover;'
                'border-radius:8px;border:1px solid #E7DEF6;" />', photo)
        return format_html(
            '<span style="color:#9A93AE;font-size:12px;">нет фото</span>')


@admin.register(Product)
class ProductAdmin(ModelAdmin):
    list_display = (
        'thumb', 'name', 'category', 'price_label', 'premium_label',
        'sold_label', 'is_active', 'in_stock',
    )
    list_display_links = ('thumb', 'name')
    list_editable = ('is_active', 'in_stock')
    list_filter = ('category', 'is_active', 'in_stock')
    search_fields = ('name', 'name_ky', 'name_en', 'description')
    autocomplete_fields = ('category',)
    inlines = (ProductOptionInline,)
    readonly_fields = ('preview', 'created_at', 'updated_at')
    list_per_page = 25
    fieldsets = (
        ('Основное', {
            'fields': ('name', 'category', 'price', 'cost_price', 'old_price',
                       'premium_price', 'description'),
        }),
        ('Переводы', {
            'classes': ('collapse',),
            'fields': ('name_ky', 'name_en', 'description_ky',
                       'description_en'),
        }),
        ('Фото', {
            'fields': ('preview', 'image', 'image_url'),
        }),
        ('Доступность', {
            'fields': ('is_active', 'in_stock'),
        }),
        ('Служебное', {
            'classes': ('collapse',),
            'fields': ('created_at', 'updated_at'),
        }),
    )

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.annotate(_sold=Sum(
            'orderitem__quantity',
            filter=~Q(orderitem__order__status='cancelled'),
        ))

    @admin.display(description='Продано', ordering='_sold')
    def sold_label(self, obj):
        n = obj._sold or 0
        return format_html(
            '<span style="background:#E7F6EC;color:#1E9E54;'
            'padding:2px 10px;border-radius:10px;font-weight:600;">{} шт.</span>',
            n)

    @admin.display(description='')
    def thumb(self, obj):
        if obj.photo:
            return format_html(
                '<img src="{}" style="width:46px;height:46px;'
                'object-fit:cover;border-radius:10px;" />', obj.photo)
        return format_html(
            '<div style="width:46px;height:46px;border-radius:10px;'
            'background:#F6F2FD;"></div>')

    @admin.display(description='Фото')
    def preview(self, obj):
        if obj.photo:
            return format_html(
                '<img src="{}" style="max-width:240px;border-radius:14px;" />',
                obj.photo)
        return '— фото не задано —'

    def save_model(self, request, obj, form, change):
        had_discount = False
        if change:
            prev = Product.objects.filter(pk=obj.pk).first()
            had_discount = bool(prev and prev.old_price
                                and prev.old_price > prev.price)
        super().save_model(request, obj, form, change)
        # Новая скидка — уведомить тех, у кого товар в избранном.
        if obj.discount_percent > 0 and not had_discount:
            _notify_discount(obj)

    @admin.display(description='Цена', ordering='price')
    def price_label(self, obj):
        if obj.discount_percent:
            return format_html(
                '<b style="color:#7A18E0;">{} сом</b> '
                '<s style="color:#9A93AE;">{}</s> '
                '<span style="background:#E5484D;color:#fff;padding:1px 6px;'
                'border-radius:8px;font-size:11px;">-{}%</span>',
                int(obj.price), int(obj.old_price), obj.discount_percent)
        return format_html(
            '<b style="color:#7A18E0;">{} сом</b>', int(obj.price))

    @admin.display(description='Premium', ordering='premium_price')
    def premium_label(self, obj):
        if obj.premium_price and obj.premium_price < obj.price:
            return format_html(
                '<b style="color:#1E9E54;">{} сом</b> '
                '<span style="background:#1E9E54;color:#fff;padding:1px 6px;'
                'border-radius:8px;font-size:11px;">★ -{}%</span>',
                int(obj.premium_price), obj.premium_discount_percent)
        return format_html('<span style="color:#9A93AE;">—</span>')


class OrderItemInline(TabularInline):
    model = OrderItem
    extra = 0
    autocomplete_fields = ('product',)
    fields = ('product', 'product_name', 'options', 'price', 'quantity',
              'line_total')
    readonly_fields = ('line_total',)

    @admin.display(description='Сумма')
    def line_total(self, obj):
        if obj.pk:
            return f'{int(obj.total)} сом'
        return '—'


@admin.register(Order)
class OrderAdmin(ModelAdmin):
    list_display = (
        'number', 'customer', 'status_badge', 'payment',
        'paid_badge', 'total_label', 'items_count', 'created_at',
    )
    list_display_links = ('number',)
    list_filter = ('status', 'payment', 'is_paid', 'created_at')
    search_fields = ('number', 'delivery_name', 'delivery_phone', 'city')
    date_hierarchy = 'created_at'
    inlines = (OrderItemInline,)
    list_select_related = ('customer',)
    readonly_fields = ('number', 'created_at', 'totals_box')
    list_per_page = 30
    actions = ('mark_confirmed', 'mark_delivering', 'mark_delivered',
               'mark_paid')

    def _set_status(self, request, queryset, new_status):
        count = 0
        for order in queryset:
            if order.status != new_status:
                order.status = new_status
                order.save(update_fields=['status'])
                _notify_order_status(order)
                count += 1
        return count

    @admin.action(description='✓ Подтвердить выбранные')
    def mark_confirmed(self, request, queryset):
        n = self._set_status(request, queryset, Order.Status.CONFIRMED)
        self.message_user(request, f'Подтверждено заказов: {n}')

    @admin.action(description='🚚 В доставку')
    def mark_delivering(self, request, queryset):
        n = self._set_status(request, queryset, Order.Status.DELIVERING)
        self.message_user(request, f'Отправлено в доставку: {n}')

    @admin.action(description='📦 Доставлен')
    def mark_delivered(self, request, queryset):
        n = self._set_status(request, queryset, Order.Status.DELIVERED)
        self.message_user(request, f'Отмечено доставленными: {n}')

    @admin.action(description='💳 Отметить оплаченными')
    def mark_paid(self, request, queryset):
        n = queryset.update(is_paid=True)
        self.message_user(request, f'Отмечено оплаченными: {n}')

    def save_model(self, request, obj, form, change):
        old_status = None
        if change:
            prev = Order.objects.filter(pk=obj.pk).first()
            old_status = prev.status if prev else None
        super().save_model(request, obj, form, change)
        if change and old_status != obj.status:
            _notify_order_status(obj)
    fieldsets = (
        ('Заказ', {
            'fields': ('number', 'customer', 'status', 'payment', 'is_paid'),
        }),
        ('Доставка', {
            'fields': ('delivery_name', 'delivery_phone', 'city',
                       'address', 'comment', 'delivery_fee'),
        }),
        ('Итоги', {
            'fields': ('totals_box', 'created_at'),
        }),
    )

    _STATUS_COLORS = {
        'processing': '#8A6D1A',
        'confirmed': '#1366D6',
        'delivering': '#7A18E0',
        'delivered': '#1E9E54',
        'cancelled': '#C2334D',
    }

    @admin.display(description='Статус', ordering='status')
    def status_badge(self, obj):
        color = self._STATUS_COLORS.get(obj.status, '#6E6788')
        return format_html(
            '<span style="background:{}1A;color:{};padding:3px 10px;'
            'border-radius:10px;font-weight:600;white-space:nowrap;">{}</span>',
            color, color, obj.get_status_display(),
        )

    @admin.display(description='Оплата')
    def paid_badge(self, obj):
        if obj.is_paid:
            return format_html(
                '<span style="color:#1E9E54;font-weight:600;">✓ оплачен</span>')
        return format_html(
            '<span style="color:#C2334D;">не оплачен</span>')

    @admin.display(description='Сумма')
    def total_label(self, obj):
        return format_html(
            '<b style="color:#7A18E0;">{} сом</b>', int(obj.grand_total))

    @admin.display(description='Итоги заказа')
    def totals_box(self, obj):
        if not obj.pk:
            return '— сохраните заказ —'
        return format_html(
            '<div style="line-height:1.8;">'
            'Товары: <b>{} сом</b><br>'
            'Доставка: <b>{} сом</b><br>'
            '<span style="font-size:16px;">Итого: '
            '<b style="color:#7A18E0;">{} сом</b></span></div>',
            int(obj.items_total), int(obj.delivery_fee), int(obj.grand_total),
        )

    # --- Отчёт по продажам ---
    def get_urls(self):
        custom = [
            path('sales-report/',
                 self.admin_site.admin_view(self.sales_report_view),
                 name='sales_report'),
        ]
        return custom + super().get_urls()

    def sales_report_view(self, request):
        items = OrderItem.objects.exclude(order__status='cancelled')
        rows = list(items.values('product_name').annotate(
            units=Sum('quantity'),
            revenue=Sum(F('price') * F('quantity'),
                        output_field=DecimalField()),
            cost=Sum(F('cost') * F('quantity'),
                     output_field=DecimalField()),
        ).order_by('-revenue'))
        for r in rows:
            r['revenue'] = r['revenue'] or 0
            r['cost'] = r['cost'] or 0
            r['profit'] = r['revenue'] - r['cost']
            r['margin'] = (round(r['profit'] / r['revenue'] * 100)
                           if r['revenue'] else 0)

        totals = {
            'units': sum((r['units'] for r in rows), 0),
            'revenue': sum((r['revenue'] for r in rows), 0),
            'cost': sum((r['cost'] for r in rows), 0),
        }
        totals['profit'] = totals['revenue'] - totals['cost']
        totals['margin'] = (round(totals['profit'] / totals['revenue'] * 100)
                            if totals['revenue'] else 0)

        orders = Order.objects.all()
        context = {
            **self.admin_site.each_context(request),
            'title': 'Отчёт по продажам',
            'rows': rows,
            'totals': totals,
            'orders_count': orders.count(),
            'paid_count': orders.filter(is_paid=True).count(),
            'cancelled_count': orders.filter(status='cancelled').count(),
        }
        return TemplateResponse(request, 'admin/sales_report.html', context)


@admin.register(Customer)
class CustomerAdmin(ModelAdmin):
    list_display = ('name', 'phone', 'email', 'premium_badge',
                    'orders_badge', 'created_at')
    list_display_links = ('name', 'phone')
    list_filter = ('is_premium',)
    search_fields = ('name', 'phone', 'email')
    readonly_fields = ('created_at', 'reset_code', 'reset_code_at')
    actions = ('grant_premium_action', 'revoke_premium_action')
    fieldsets = (
        ('Покупатель', {'fields': ('name', 'phone', 'email')}),
        ('Premium', {'fields': ('is_premium', 'premium_until')}),
        ('Служебное', {
            'classes': ('collapse',),
            'fields': ('created_at', 'reset_code', 'reset_code_at'),
        }),
    )

    def get_queryset(self, request):
        return super().get_queryset(request).annotate(_oc=Count('orders'))

    @admin.display(description='Заказов', ordering='_oc')
    def orders_badge(self, obj):
        return format_html(
            '<span style="background:#F0E7FC;color:#7A18E0;'
            'padding:2px 10px;border-radius:10px;font-weight:600;">{}</span>',
            obj._oc,
        )

    @admin.display(description='Статус', ordering='is_premium')
    def premium_badge(self, obj):
        if obj.premium_active:
            until = obj.premium_until
            extra = f' до {until:%d.%m.%Y}' if until else ' (бессрочно)'
            return format_html(
                '<span style="background:#1E9E54;color:#fff;padding:2px 10px;'
                'border-radius:10px;font-weight:600;">★ Premium{}</span>',
                extra)
        return format_html(
            '<span style="background:#EFECF6;color:#6E6788;padding:2px 10px;'
            'border-radius:10px;">обычный</span>')

    @admin.action(description='★ Выдать Premium (30 дней)')
    def grant_premium_action(self, request, queryset):
        for customer in queryset:
            customer.grant_premium(days=30)
        self.message_user(
            request, f'Premium выдан покупателям: {queryset.count()}')

    @admin.action(description='✕ Снять Premium')
    def revoke_premium_action(self, request, queryset):
        n = queryset.update(is_premium=False, premium_until=None)
        self.message_user(request, f'Premium снят: {n}')


@admin.register(Favorite)
class FavoriteAdmin(ModelAdmin):
    list_display = ('customer', 'product', 'created_at')
    search_fields = ('customer__name', 'customer__phone', 'product__name')
    autocomplete_fields = ('customer', 'product')


class ReviewReplyInline(TabularInline):
    model = ReviewReply
    extra = 1
    fields = ('author_name', 'is_seller', 'text', 'created_at')
    readonly_fields = ('created_at',)


@admin.register(Review)
class ReviewAdmin(ModelAdmin):
    list_display = ('product', 'author_name', 'stars', 'short_text',
                    'replies_count', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('product__name', 'author_name', 'text')
    autocomplete_fields = ('product', 'customer')
    readonly_fields = ('created_at',)
    inlines = (ReviewReplyInline,)

    @admin.display(description='Оценка', ordering='rating')
    def stars(self, obj):
        full = '★' * obj.rating
        empty = '☆' * (5 - obj.rating)
        return format_html(
            '<span style="color:#FFB300;font-size:15px;">{}</span>'
            '<span style="color:#D8D0EA;font-size:15px;">{}</span>',
            full, empty)

    @admin.display(description='Отзыв')
    def short_text(self, obj):
        return (obj.text[:60] + '…') if len(obj.text) > 60 else obj.text

    @admin.display(description='Ответов')
    def replies_count(self, obj):
        return obj.replies.count()


# --- Уведомления ---

def _notify_order_status(order):
    if not order.customer:
        return
    Notification.objects.create(
        customer=order.customer,
        kind=Notification.Kind.ORDER,
        title=f'Заказ {order.number}: {order.get_status_display()}',
        body=f'Статус вашего заказа обновлён: {order.get_status_display()}.',
    )


def _notify_discount(product):
    customers = Customer.objects.filter(
        favorites__product=product).distinct()
    Notification.objects.bulk_create([
        Notification(
            customer=c,
            kind=Notification.Kind.DISCOUNT,
            title=f'Скидка на «{product.name}»',
            body=f'Теперь {int(product.price)} сом '
                 f'(−{product.discount_percent}%). Успейте купить!',
            product=product,
        )
        for c in customers
    ])


@admin.register(Notification)
class NotificationAdmin(ModelAdmin):
    list_display = ('title', 'customer', 'kind', 'is_read', 'created_at')
    list_filter = ('kind', 'is_read', 'created_at')
    search_fields = ('title', 'body', 'customer__name', 'customer__phone')
    autocomplete_fields = ('customer', 'product')
    readonly_fields = ('created_at',)


@admin.register(Broadcast)
class BroadcastAdmin(ModelAdmin):
    list_display = ('title', 'audience', 'product', 'sent', 'sent_count',
                    'created_at')
    list_filter = ('audience', 'sent')
    search_fields = ('title', 'body')
    autocomplete_fields = ('product',)
    readonly_fields = ('sent', 'sent_count', 'created_at')
    actions = ('send_selected',)
    fieldsets = (
        ('Сообщение', {'fields': ('title', 'body')}),
        ('Аудитория', {'fields': ('audience', 'product')}),
        ('Статус', {'fields': ('sent', 'sent_count', 'created_at')}),
    )

    @admin.action(description='📣 Отправить выбранные рассылки')
    def send_selected(self, request, queryset):
        total = 0
        for broadcast in queryset:
            total += broadcast.send()
        self.message_user(
            request, f'Отправлено уведомлений: {total}')
