import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../l10n/l10n.dart';
import 'catalog_screen.dart';
import 'notifications_screen.dart';
import 'premium_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = <String, IconData>{
    'Электроника': Icons.devices_other_rounded,
    'Одежда': Icons.checkroom_rounded,
    'Дом и сад': Icons.chair_rounded,
    'Красота': Icons.spa_rounded,
    'Спорт': Icons.sports_basketball_rounded,
  };

  void _openCatalog(BuildContext context,
      {String category = 'Все', String query = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogScreen(
          standalone: true,
          initialCategory: category,
          initialQuery: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final name =
        state.userName.isNotEmpty ? state.userName : context.tr('Гость');

    final cats = state.categoryList;
    final popular = state.products.take(6).toList();
    final recommended = state.products.reversed.take(6).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Greeting + logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Добро пожаловать 👋'),
                        style: TextStyle(fontSize: 13, color: c.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Badge(
                      isLabelVisible: state.unreadCount > 0,
                      label: Text('${state.unreadCount}'),
                      backgroundColor: const Color(0xFFE5484D),
                      child: Icon(Icons.notifications_none_rounded,
                          size: 28, color: c.ink),
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/logo/juzum_glyph_white.png',
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.offline)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5484D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 18, color: Color(0xFFE5484D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('Нет связи с сервером — показаны демо-товары'),
                        style: TextStyle(fontSize: 12, color: c.ink),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => state.loadCatalog(),
                      child: Text(
                        context.tr('Повторить'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.solid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Search (открывает каталог)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _openCatalog(context, query: v.trim()),
              decoration: InputDecoration(
                hintText: context.tr('Искать товары...'),
                prefixIcon: Icon(Icons.search, color: c.grey),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Promo banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _openCatalog(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(AppColors.rCard),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Скидки до 50%'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                                'Лучшие товары недели\nпо специальным ценам'),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.tr('Смотреть'),
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
                    const Icon(Icons.local_offer_rounded,
                        size: 64, color: Colors.white24),
                  ],
                ),
              ),
            ),
          ),
          // Объявление о Premium — только если ещё не подключён
          if (!state.isPremium) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(AppColors.rCard),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.premiumGold.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Подключите Premium'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                  'Специальные цены на товары — навсегда'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          // Categories
          _SectionHeader(title: context.tr('Категории')),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final cat = cats[i];
                return GestureDetector(
                  onTap: () => _openCatalog(context, category: cat.key),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: c.tint,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: c.line),
                        ),
                        child: Icon(
                          // Иконка по ключу (рус. имя) — работает на всех языках.
                          _categoryIcons[cat.key] ?? Icons.category_rounded,
                          color: AppColors.solid,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 68,
                        child: Text(
                          cat.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          // Персональная подборка по интересам
          if (state.hasInterest) ...[
            _SectionHeader(
              title: context.tr('Специально для вас'),
              onSeeAll: () => _openCatalog(context),
            ),
            const SizedBox(height: 12),
            _ProductRail(products: state.recommended.take(8).toList()),
            const SizedBox(height: 22),
          ],
          // Popular
          _SectionHeader(
            title: context.tr('Популярное'),
            onSeeAll: () => _openCatalog(context),
          ),
          const SizedBox(height: 12),
          _ProductRail(products: popular),
          const SizedBox(height: 22),
          // Recommended
          _SectionHeader(
            title: context.tr('Рекомендуем вам'),
            onSeeAll: () => _openCatalog(context),
          ),
          const SizedBox(height: 12),
          _ProductRail(products: recommended),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                context.tr('Все'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.solid,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  final List<Product> products;

  const _ProductRail({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: 150,
          child: ProductCard(product: products[i]),
        ),
      ),
    );
  }
}
