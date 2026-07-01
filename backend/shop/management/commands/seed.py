import json
import os
from django.core.management.base import BaseCommand
from shop.models import (
    Category, Product, Customer, Review, ReviewReply, ProductOption,
    OrderItem,
)

# Файл с реальными фото товаров (чистые каталожные снимки на белом фоне).
IMAGES_FILE = os.path.join(os.path.dirname(__file__), 'seed_images.json')

# Варианты товара: ru name -> [(группа, значение, надбавка, фото-ссылка)]
# У вариантов цвета — своё фото (пользователь листает галерею и выбирает цвет).
def _img(seed):
    """Тематическое фото по ключевым словам (loremflickr).
    Дефисы в seed = разные ключевые слова, напр. 'headphones-black'."""
    kw = seed.replace('-', ',')
    lock = sum(ord(c) for c in seed)  # стабильная картинка на seed
    return f'https://loremflickr.com/400/400/{kw}?lock={lock}'


OPTIONS = {
    'Беспроводные наушники': [
        ('Цвет', 'Чёрный', 0, _img('headphones-black')),
        ('Цвет', 'Белый', 0, _img('headphones-white')),
        ('Цвет', 'Синий', 100, _img('headphones-blue')),
    ],
    'Смарт-часы Pro': [
        ('Цвет', 'Чёрный', 0, _img('watch-black')),
        ('Цвет', 'Серебристый', 0, _img('watch-silver')),
        ('Модель', '42 мм', 0, ''), ('Модель', '46 мм', 700, ''),
    ],
    'Портативная колонка': [
        ('Цвет', 'Чёрный', 0, _img('speaker-black')),
        ('Цвет', 'Красный', 0, _img('speaker-red')),
    ],
    'Худи оверсайз': [
        ('Цвет', 'Серый', 0, _img('hoodie-grey')),
        ('Цвет', 'Чёрный', 200, _img('hoodie-black')),
        ('Размер', 'M', 0, ''), ('Размер', 'L', 0, ''),
        ('Размер', 'XL', 150, ''),
    ],
    'Кроссовки Air': [
        ('Размер', '40', 0, ''), ('Размер', '41', 0, ''),
        ('Размер', '42', 0, ''), ('Размер', '43', 0, ''),
    ],
    'Джинсы Slim Fit': [
        ('Размер', '30', 0, ''), ('Размер', '32', 0, ''),
        ('Размер', '34', 0, ''),
    ],
}

# Скидки: название товара -> старая цена (сом)
DISCOUNTS = {
    'Беспроводные наушники': 3290,
    'Смарт-часы Pro': 11990,
    'Кроссовки Air': 6900,
    'Парфюм Blossom': 5200,
    'Гантели 2×3 кг': 2990,
}

# Примеры отзывов: название товара -> [(имя, оценка, текст, ответ_магазина)]
REVIEWS = {
    'Беспроводные наушники': [
        ('Айбек', 5, 'Звук топ, шумодав реально работает в маршрутке!',
         'Спасибо за отзыв! Рады, что понравилось 🎧'),
        ('Нургуль', 4, 'Хорошие, но чехол бы поплотнее.', None),
    ],
    'Смарт-часы Pro': [
        ('Данияр', 5, 'Батарея держит 3 дня, доволен.', None),
    ],
}

CATEGORIES = [
    ('Электроника', 'devices_other_rounded'),
    ('Одежда', 'checkroom_rounded'),
    ('Дом и сад', 'chair_rounded'),
    ('Красота', 'spa_rounded'),
    ('Спорт', 'sports_basketball_rounded'),
]

# Переводы категорий: ru -> (kyrgyz, english)
CATEGORY_TR = {
    'Электроника': ('Электроника', 'Electronics'),
    'Одежда': ('Кийим', 'Clothing'),
    'Дом и сад': ('Үй жана бак', 'Home & Garden'),
    'Красота': ('Сулуулук', 'Beauty'),
    'Спорт': ('Спорт', 'Sports'),
}

# Переводы товаров: ru name -> (name_ky, name_en, desc_ky, desc_en)
PRODUCT_TR = {
    'Беспроводные наушники': (
        'Зымсыз кулакчындар', 'Wireless earphones',
        'Шуу басуучу Bluetooth кулакчындар, 24 саатка чейин иштейт. '
        'Терең бас жана таза жогорку жыштыктар.',
        'Bluetooth earphones with noise cancellation, up to 24 hours of '
        'playback. Deep bass and clear highs.'),
    'Смарт-часы Pro': (
        'Смарт-саат Pro', 'Smartwatch Pro',
        'Фитнес-трекер, уйку, пульс жана SpO2 мониторинги. IP68 суудан '
        'коргоо. AMOLED дисплей.',
        'Fitness tracker, sleep, heart rate and SpO2 monitoring. IP68 water '
        'resistance. AMOLED display.'),
    'Портативная колонка': (
        'Көчмө колонка', 'Portable speaker',
        'Кубаттуу 20Вт үн, IPX7 суудан коргоо. 12 саатка чейин автоном иштөө.',
        'Powerful 20W sound, IPX7 water protection. Up to 12 hours of '
        'battery life.'),
    'Худи оверсайз': (
        'Оверсайз худи', 'Oversized hoodie',
        'Пахтадан тигилген жумшак, эркин кесимдеги худи. Ыңгайлуу капюшон '
        'жана кенгуру-чөнтөк.',
        'Soft loose-fit cotton hoodie. Comfy hood and kangaroo pocket.'),
    'Кроссовки Air': (
        'Air кроссовкалары', 'Air sneakers',
        'Амортизациялуу жеңил кроссовкалар. Дем алуучу үстү, шаар үчүн '
        'ыңгайлуу таман.',
        'Lightweight cushioned sneakers. Breathable upper, comfortable sole '
        'for the city.'),
    'Джинсы Slim Fit': (
        'Slim Fit джинсы', 'Slim Fit jeans',
        'Тарыраак кесимдеги классикалык джинсы. Эластик деним, ыңгайлуу '
        'отуруу.',
        'Classic slim-cut jeans. Stretch denim, comfortable fit.'),
    'LED-гирлянда': (
        'LED-гирлянда', 'LED string lights',
        '10м гирлянда, жылуу жарык, 100 LED. Тармактан иштейт, 8 жарык режими.',
        '10m garland, warm light, 100 LEDs. Mains-powered, 8 lighting modes.'),
    'Керамический горшок': (
        'Керамикалык гүлидиш', 'Ceramic pot',
        'Бөлмө өсүмдүктөрү үчүн шик гүлидиш. Минималисттик дизайн, дренаж '
        'тешиги.',
        'Stylish pot for indoor plants. Minimalist design, drainage hole.'),
    'Плед из микрофибры': (
        'Микрофибра жууркан', 'Microfiber blanket',
        'Жумшак жана жылуу жууркан 150×200 см. Түктөнбөйт, оңой жуулат.',
        "Soft and warm blanket 150×200 cm. Doesn't pill, easy to wash."),
    'Набор кистей для макияжа': (
        'Макияж щёткаларынын топтому', 'Makeup brush set',
        'Былгары кабында 12 синтетикалык щётка. Бет жана көз үчүн.',
        '12 synthetic brushes in a leather case. For face and eyes.'),
    'Увлажняющий крем': (
        'Нымдандыруучу крем', 'Moisturizing cream',
        'Гиалурон кислотасы жана E витамини бар крем. Бардык тери түрлөрү '
        'үчүн, 50 мл.',
        'Cream with hyaluronic acid and vitamin E. For all skin types, '
        '50 ml.'),
    'Парфюм Blossom': (
        'Blossom атыры', 'Blossom perfume',
        'Гүл-жемиш жыты. Пион, бергамот жана ак мускус ноталары. 50 мл.',
        'Floral-fruity fragrance. Notes of peony, bergamot and white musk. '
        '50 ml.'),
    'Коврик для йоги': (
        'Йога килемчеси', 'Yoga mat',
        'Тайгаланбас килемче 183×61 см, калыңдыгы 6 мм. Жеңил жана алып '
        'жүрүүгө ыңгайлуу.',
        'Non-slip mat 183×61 cm, 6 mm thick. Light and easy to carry.'),
    'Гантели 2×3 кг': (
        'Гантель 2×3 кг', 'Dumbbells 2×3 kg',
        'Тайгаланбас каптоолуу винил гантелдер. Үй машыгуулары үчүн эң сонун.',
        'Vinyl dumbbells with non-slip coating. Perfect for home workouts.'),
    'Бутылка для воды': (
        'Суу бөтөлкөсү', 'Water bottle',
        'Тритандан жасалган спорттук бөтөлкө 750 мл. BPA-сыз, ыңгайлуу капкак.',
        '750 ml tritan sports bottle. BPA-free, convenient sip lid.'),
    'Фитнес-резинки набор': (
        'Фитнес-резинкалар топтому', 'Fitness bands set',
        'Ар кандай катуулуктагы 5 резинканын топтому. Жылытуу, күч жана '
        'чоюлуу үчүн.',
        'Set of 5 bands of different resistance. For warm-up, strength and '
        'stretching.'),
}

PRODUCTS = [
    ('Беспроводные наушники', 2490, 'Электроника',
     'Bluetooth наушники с шумоподавлением, до 24 часов работы. Глубокий бас и чистые высокие частоты.',
     'https://loremflickr.com/400/400/headphones?lock=1055'),
    ('Смарт-часы Pro', 8990, 'Электроника',
     'Фитнес-трекер, мониторинг сна, пульса и SpO2. Водозащита IP68. AMOLED дисплей.',
     'https://loremflickr.com/400/400/smartwatch?lock=1086'),
    ('Портативная колонка', 3450, 'Электроника',
     'Мощный звук 20Вт, защита от воды IPX7. До 12 часов автономной работы.',
     'https://loremflickr.com/400/400/bluetooth,speaker?lock=1774'),
    ('Худи оверсайз', 2200, 'Одежда',
     'Мягкое худи свободного кроя из хлопка. Удобный капюшон и карман-кенгуру.',
     'https://loremflickr.com/400/400/hoodie?lock=632'),
    ('Кроссовки Air', 5690, 'Одежда',
     'Лёгкие кроссовки с амортизацией. Дышащий верх, удобная подошва для города.',
     'https://loremflickr.com/400/400/sneakers?lock=860'),
    ('Джинсы Slim Fit', 3100, 'Одежда',
     'Классические джинсы зауженного кроя. Эластичный деним, комфортная посадка.',
     'https://loremflickr.com/400/400/jeans?lock=529'),
    ('LED-гирлянда', 890, 'Дом и сад',
     'Гирлянда 10м, тёплый свет, 100 LED. Работает от сети, 8 режимов свечения.',
     'https://loremflickr.com/400/400/fairy,lights?lock=1235'),
    ('Керамический горшок', 1250, 'Дом и сад',
     'Стильный горшок для комнатных растений. Минималистичный дизайн, дренажное отверстие.',
     'https://loremflickr.com/400/400/flower,pot?lock=1039'),
    ('Плед из микрофибры', 1790, 'Дом и сад',
     'Мягкий и тёплый плед 150×200 см. Не скатывается, легко стирается.',
     'https://loremflickr.com/400/400/blanket?lock=737'),
    ('Набор кистей для макияжа', 1450, 'Красота',
     '12 кистей из синтетического ворса в кожаном чехле. Для лица и глаз.',
     'https://loremflickr.com/400/400/makeup,brush?lock=1236'),
    ('Увлажняющий крем', 980, 'Красота',
     'Крем с гиалуроновой кислотой и витамином E. Для всех типов кожи, 50 мл.',
     'https://loremflickr.com/400/400/skincare,cream?lock=1413'),
    ('Парфюм Blossom', 4200, 'Красота',
     'Цветочно-фруктовый аромат. Ноты пиона, бергамота и белого мускуса. 50 мл.',
     'https://loremflickr.com/400/400/perfume?lock=756'),
    ('Коврик для йоги', 1590, 'Спорт',
     'Нескользящий коврик 183×61 см, толщина 6 мм. Лёгкий и удобный для переноски.',
     'https://loremflickr.com/400/400/yoga,mat?lock=799'),
    ('Гантели 2×3 кг', 2300, 'Спорт',
     'Виниловые гантели с нескользящим покрытием. Идеальны для домашних тренировок.',
     'https://loremflickr.com/400/400/dumbbell?lock=839'),
    ('Бутылка для воды', 690, 'Спорт',
     'Спортивная бутылка 750 мл из тритана. BPA-free, удобная крышка-поилка.',
     'https://loremflickr.com/400/400/water,bottle?lock=1242'),
    ('Фитнес-резинки набор', 1100, 'Спорт',
     'Набор из 5 резинок разной жёсткости. Для разминки, силовых и растяжки.',
     'https://loremflickr.com/400/400/fitness,band?lock=1214'),
]


class Command(BaseCommand):
    help = 'Наполняет базу категориями и товарами JUZUM (как в приложении).'

    def handle(self, *args, **options):
        cats = {}
        for order, (name, icon) in enumerate(CATEGORIES):
            ky, en = CATEGORY_TR.get(name, ('', ''))
            cat, _ = Category.objects.update_or_create(
                name=name,
                defaults={'icon': icon, 'order': order, 'is_active': True,
                          'name_ky': ky, 'name_en': en},
            )
            cats[name] = cat
        self.stdout.write(self.style.SUCCESS(
            f'Категорий: {Category.objects.count()}'))

        created = 0
        for name, price, cat_name, desc, url in PRODUCTS:
            name_ky, name_en, desc_ky, desc_en = PRODUCT_TR.get(
                name, ('', '', '', ''))
            _, was_created = Product.objects.update_or_create(
                name=name,
                defaults={
                    'category': cats[cat_name],
                    'price': price,
                    'description': desc,
                    'image_url': url,
                    'is_active': True,
                    'in_stock': True,
                    'name_ky': name_ky,
                    'name_en': name_en,
                    'description_ky': desc_ky,
                    'description_en': desc_en,
                },
            )
            created += int(was_created)
        self.stdout.write(self.style.SUCCESS(
            f'Товаров всего: {Product.objects.count()} (новых: {created})'))

        # Скидки
        for name, old in DISCOUNTS.items():
            Product.objects.filter(name=name).update(old_price=old)
        self.stdout.write(self.style.SUCCESS(
            f'Скидок проставлено: {len(DISCOUNTS)}'))

        # Премиум-цены: ~10% ниже обычной, округляя до 10 сом.
        premium_set = 0
        for product in Product.objects.all():
            premium = int(round(float(product.price) * 0.9 / 10)) * 10
            if premium and premium < product.price:
                Product.objects.filter(pk=product.pk).update(
                    premium_price=premium)
                premium_set += 1
        self.stdout.write(self.style.SUCCESS(
            f'Премиум-цен проставлено: {premium_set}'))

        # Себестоимость ≈ 60% от цены (для отчёта прибыли).
        for product in Product.objects.all():
            cost = int(round(float(product.price) * 0.6 / 10)) * 10
            Product.objects.filter(pk=product.pk).update(cost_price=cost)
        self.stdout.write(self.style.SUCCESS('Себестоимость проставлена'))

        # Варианты (цвет/модель/размер)
        opt_count = 0
        for prod_name, opts in OPTIONS.items():
            product = Product.objects.filter(name=prod_name).first()
            if not product:
                continue
            for order, (group, value, delta, img) in enumerate(opts):
                ProductOption.objects.update_or_create(
                    product=product, group=group, value=value,
                    defaults={'price_delta': delta, 'order': order,
                              'is_active': True, 'image_url': img},
                )
                opt_count += 1
        self.stdout.write(self.style.SUCCESS(
            f'Вариантов проставлено: {opt_count}'))

        # Реальные фото товаров и вариантов цвета (из seed_images.json).
        if os.path.exists(IMAGES_FILE):
            data = json.load(open(IMAGES_FILE, encoding='utf-8'))
            pset = 0
            for name, url in data.get('products', {}).items():
                pset += Product.objects.filter(name=name).update(
                    image_url=url, image='')
            cset = 0
            for name, urls in data.get('colors', {}).items():
                product = Product.objects.filter(name=name).first()
                if not product:
                    continue
                colors = list(product.options.filter(group='Цвет')
                              .order_by('order', 'id'))
                for opt, url in zip(colors, urls):
                    ProductOption.objects.filter(pk=opt.pk).update(
                        image_url=url, image='')
                    cset += 1
            self.stdout.write(self.style.SUCCESS(
                f'Фото товаров: {pset}, фото вариантов: {cset}'))

        # Бэкфилл себестоимости в старых позициях заказа.
        filled = 0
        for item in OrderItem.objects.filter(cost=0).select_related('product'):
            if item.product and item.product.cost_price:
                item.cost = item.product.cost_price
                item.save(update_fields=['cost'])
                filled += 1
        self.stdout.write(self.style.SUCCESS(
            f'Себестоимость в позициях заполнена: {filled}'))

        # Демо премиум-аккаунт для проверки (бессрочный премиум).
        Customer.objects.update_or_create(
            phone='+996555111222',
            defaults={'name': 'Премиум Демо', 'is_premium': True},
        )
        self.stdout.write(self.style.SUCCESS(
            'Демо премиум-аккаунт: +996555111222'))

        # Примеры отзывов (только если их ещё нет)
        demo_customer, _ = Customer.objects.get_or_create(
            phone='+996500000000', defaults={'name': 'Демо-покупатель'})
        added = 0
        for prod_name, items in REVIEWS.items():
            product = Product.objects.filter(name=prod_name).first()
            if not product or product.reviews.exists():
                continue
            for author, rating, text, seller_reply in items:
                review = Review.objects.create(
                    product=product, customer=demo_customer,
                    author_name=author, rating=rating, text=text)
                added += 1
                if seller_reply:
                    ReviewReply.objects.create(
                        review=review, author_name='JUZUM',
                        is_seller=True, text=seller_reply)
        self.stdout.write(self.style.SUCCESS(f'Отзывов добавлено: {added}'))
