import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../screens/product_screen.dart';
import '../l10n/l10n.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  /// Стабильный псевдо-рейтинг 4.6–5.0 на основе id товара.
  double get _rating => 4.6 + (product.id.hashCode.abs() % 5) / 10;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppColors.rCard),
          border: dark ? Border.all(color: c.line) : null,
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.indigo.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Фото ---
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppColors.rCard),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: c.tint,
                      child: product.imageUrl.isEmpty
                          ? Center(
                              child: Icon(Icons.image,
                                  size: 40, color: c.grey))
                          : Image.network(
                              product.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.image,
                                    size: 40, color: c.grey),
                              ),
                            ),
                    ),
                  ),
                  // Бейдж скидки
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5484D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  // Избранное
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => state.toggleFavorite(product),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          product.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 17,
                          color: product.isFavorite
                              ? AppColors.violet
                              : const Color(0xFF9A93AE),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // --- Инфо ---
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Рейтинг
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(
                        (product.reviewsCount > 0 ? product.rating : _rating)
                            .toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      if (product.reviewsCount > 0)
                        Text(
                          ' (${product.reviewsCount})',
                          style: TextStyle(fontSize: 11, color: c.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Builder(builder: (context) {
                          final premium =
                              state.isPremium && product.hasPremiumPrice;
                          final shown = state.priceOf(product);
                          final double? struck = premium
                              ? product.price
                              : (product.hasDiscount ? product.oldPrice : null);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (struck != null)
                                Text(
                                  context.trp('{v} сом',
                                      {'v': '${struck.toInt()}'}),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${shown.toInt()} ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: premium
                                            ? AppColors.premium
                                            : AppColors.solid,
                                      ),
                                    ),
                                    TextSpan(
                                      text: context.tr('сом'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: c.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!state.isPremium && product.hasPremiumPrice)
                                Text(
                                  context.trp('★ {p} с Premium', {
                                    'p': '${product.premiumPrice!.toInt()}'
                                  }),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.premium,
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Если есть варианты — открываем товар для выбора.
                          if (product.hasOptions) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProductScreen(product: product)),
                            );
                            return;
                          }
                          state.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.trp('{name} в корзине',
                                  {'name': product.name})),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.solid,
                            ),
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.solid.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              size: 19, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
