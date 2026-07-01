import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_card.dart';
import '../l10n/l10n.dart';
import 'premium_screen.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _quantity = 1;

  List<Review> _reviews = [];
  List<Product> _similar = [];
  bool _loadingReviews = true;

  /// Выбранный вариант в каждой группе (группа -> значение).
  final Map<String, ProductOptionValue> _selected = {};

  /// Галерея фото (карусель) — листание выбирает цвет.
  final PageController _pageController = PageController();
  int _galleryIndex = 0;

  Product get product => widget.product;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Фото для галереи: по одному на вариант группы-галереи (цвет),
  /// иначе — одно фото товара.
  List<String> get _galleryImages {
    final g = product.galleryGroup;
    if (g != null) {
      return [
        for (final o in g.options) o.hasPhoto ? o.photo : product.imageUrl,
      ];
    }
    return [product.imageUrl];
  }

  @override
  void initState() {
    super.initState();
    context.read<AppState>().recordViewCategory(product.categoryKey);
    // По умолчанию выбираем первое значение каждой группы.
    for (final g in product.optionGroups) {
      if (g.options.isNotEmpty) _selected[g.group] = g.options.first;
    }
    _loadReviews();
    _loadSimilar();
  }

  /// Суммарная надбавка за выбранные варианты.
  double get _optionsDelta =>
      _selected.values.fold(0.0, (s, o) => s + o.priceDelta);

  List<ProductOptionValue> get _selectedOptions => _selected.values.toList();

  Future<void> _loadReviews() async {
    try {
      final r = await context.read<AppState>().reviewsFor(product.id);
      if (mounted) setState(() {
        _reviews = r;
        _loadingReviews = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadSimilar() async {
    final s = await context.read<AppState>().similarTo(product);
    if (mounted) setState(() => _similar = s);
  }

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  double get _avgRating {
    if (_reviews.isEmpty) return product.rating;
    final sum = _reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Товар')),
        actions: [
          IconButton(
            icon: Icon(
              product.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: product.isFavorite ? AppColors.violet : c.grey,
            ),
            onPressed: () => state.toggleFavorite(product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Галерея фото + бейдж скидки
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _galleryImages.length,
                    onPageChanged: (i) {
                      setState(() {
                        _galleryIndex = i;
                        // Свайп по фото = выбор соответствующего цвета.
                        final g = product.galleryGroup;
                        if (g != null && i < g.options.length) {
                          _selected[g.group] = g.options[i];
                        }
                      });
                    },
                    itemBuilder: (_, i) {
                      final url = _galleryImages[i];
                      if (url.isEmpty) {
                        return Container(
                          color: c.tint,
                          child: Center(
                            child: Icon(Icons.image, size: 64, color: c.grey),
                          ),
                        );
                      }
                      return Image.network(
                        url,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: c.tint,
                          child: Center(
                            child: Icon(Icons.image, size: 64, color: c.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Точки-индикатор + текущий цвет
                if (_galleryImages.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _galleryImages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _galleryIndex ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _galleryIndex
                                  ? AppColors.solid
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (product.hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.trp('Скидка {p}%',
                            {'p': '${product.discountPercent}'}),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                // Доплата за текущий вариант (цвет дороже)
                if (product.galleryGroup != null &&
                    product.galleryGroup!.options[_galleryIndex].priceDelta > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.solid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${product.galleryGroup!.options[_galleryIndex].priceDelta.toInt()} ${context.tr('сом')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Категория + рейтинг
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.tint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.solid,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (product.reviewsCount > 0 || _reviews.isNotEmpty) ...[
                        const Icon(Icons.star_rounded,
                            size: 18, color: Color(0xFFFFB300)),
                        const SizedBox(width: 3),
                        Text(
                          _avgRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          context.trp('  {n} отз.',
                              {'n': '${_reviews.length}'}),
                          style: TextStyle(fontSize: 13, color: c.grey),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Цена (с учётом скидки и премиум-статуса)
                  Builder(builder: (context) {
                    final premium =
                        state.isPremium && product.hasPremiumPrice;
                    final shown = state.priceOf(product) + _optionsDelta;
                    final double? struck = premium
                        ? product.price + _optionsDelta
                        : (product.hasDiscount
                            ? product.oldPrice! + _optionsDelta
                            : null);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.trp('{v} сом', {'v': '${shown.toInt()}'}),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: premium
                                ? AppColors.premium
                                : AppColors.solid,
                          ),
                        ),
                        if (struck != null) ...[
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              context.trp('{v} сом',
                                  {'v': '${struck.toInt()}'}),
                              style: TextStyle(
                                fontSize: 16,
                                color: c.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                        if (premium) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _premiumTag(),
                          ),
                        ],
                      ],
                    );
                  }),
                  // Подсказка для обычных: цена с Premium
                  if (!state.isPremium && product.hasPremiumPrice) ...[
                    const SizedBox(height: 10),
                    _PremiumHint(
                      price: product.premiumPrice!,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PremiumScreen()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.grey,
                      height: 1.5,
                    ),
                  ),
                  // --- Варианты (модель/размер).
                  // Группа-галерея (цвет) выбирается листанием фото. ---
                  for (final g in product.optionGroups)
                    if (!g.hasPhotos) ...[
                    const SizedBox(height: 20),
                    Text(
                      context.tr(g.group),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in g.options)
                          _OptionChip(
                            label: o.priceDelta > 0
                                ? '${o.value}  +${o.priceDelta.toInt()}'
                                : o.value,
                            selected: _selected[g.group]?.id == o.id,
                            onTap: () =>
                                setState(() => _selected[g.group] = o),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Количество
                  Row(
                    children: [
                      Text(
                        context.tr('Количество:'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: context.trp('В корзину — {v} сом', {
                      'v': '${((state.priceOf(product) + _optionsDelta) * _quantity).toInt()}'
                    }),
                    gradient: true,
                    onPressed: () {
                      for (var i = 0; i < _quantity; i++) {
                        state.addToCart(product, options: _selectedOptions);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.trp(
                              '{name} (×{q}) добавлен в корзину',
                              {'name': product.name, 'q': '$_quantity'})),
                          backgroundColor: AppColors.solid,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // --- Похожие товары ---
            if (_similar.isNotEmpty) ...[
              _SectionTitle(context.tr('Похожие товары'), c: c),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  itemCount: _similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: 150,
                    child: ProductCard(product: _similar[i]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // --- Отзывы ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text(
                    context.tr('Отзывы'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openReviewSheet,
                    child: Text(
                      context.tr('Оставить отзыв'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.solid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loadingReviews)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Text(
                  context.tr('Пока нет отзывов. Будьте первым!'),
                  style: TextStyle(color: c.grey, fontSize: 14),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    for (final r in _reviews) _reviewTile(r, c),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reviewTile(Review r, AppPalette c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(AppColors.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.solid.withValues(alpha: 0.15),
                child: Text(
                  (r.authorName.isNotEmpty ? r.authorName[0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.solid,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.authorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    _stars(r.rating),
                  ],
                ),
              ),
              Text(_date(r.createdAt),
                  style: TextStyle(fontSize: 11, color: c.grey)),
            ],
          ),
          if (r.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.text,
                style: TextStyle(fontSize: 14, color: c.ink, height: 1.35)),
          ],
          // Ответы
          for (final reply in r.replies)
            Container(
              margin: const EdgeInsets.only(top: 10, left: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        reply.isSeller
                            ? Icons.storefront_rounded
                            : Icons.reply_rounded,
                        size: 14,
                        color: AppColors.solid,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reply.isSeller ? 'JUZUM' : reply.authorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solid,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reply.text,
                      style: TextStyle(fontSize: 13, color: c.ink)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openReplySheet(r),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.tr('Ответить'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.premium.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.tr('★ Premium'),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.premium,
        ),
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 15,
            color: const Color(0xFFFFB300),
          ),
      ],
    );
  }

  void _openReviewSheet() {
    int rating = 5;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final c = AppColors.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Ваш отзыв'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('Оценка'),
                      style: TextStyle(color: c.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => setSheet(() => rating = i),
                          child: Icon(
                            i <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 38,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: context.tr('Поделитесь впечатлениями...'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: context.tr('Отправить отзыв'),
                    gradient: true,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _submitReview(rating, controller.text.trim());
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReview(int rating, String text) async {
    try {
      await context.read<AppState>().addReview(product.id, rating, text);
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Спасибо за отзыв!')),
            backgroundColor: AppColors.solid,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      _showError();
    }
  }

  void _openReplySheet(Review review) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final c = AppColors.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Ответ на отзыв'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: context.tr('Ваш ответ...'),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: context.tr('Отправить'),
                  gradient: true,
                  onPressed: () async {
                    final text = controller.text.trim();
                    Navigator.pop(sheetContext);
                    if (text.isEmpty) return;
                    await _submitReply(review.id, text);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReply(int reviewId, String text) async {
    try {
      await context.read<AppState>().addReply(reviewId, text);
      await _loadReviews();
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Не удалось отправить. Проверьте связь.')),
        backgroundColor: const Color(0xFFE5484D),
      ),
    );
  }
}

/// Чип выбора варианта (цвет/модель/размер).
class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.solid.withValues(alpha: 0.10) : c.tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.solid : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.solid : c.ink,
          ),
        ),
      ),
    );
  }
}

/// Подсказка «цена ниже с Premium» с переходом на экран подписки.
class _PremiumHint extends StatelessWidget {
  final double price;
  final VoidCallback onTap;
  const _PremiumHint({required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.premium.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.premium.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 20, color: AppColors.premium),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.premium,
                  ),
                  children: [
                    TextSpan(text: context.tr('C Premium — ')),
                    TextSpan(
                      text: context.trp('{v} сом', {'v': '${price.toInt()}'}),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: context.tr('. Оформить →')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppPalette c;
  const _SectionTitle(this.title, {required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: c.ink,
        ),
      ),
    );
  }
}
