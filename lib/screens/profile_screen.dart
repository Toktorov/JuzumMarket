import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final name = state.userName.isNotEmpty ? state.userName : context.tr('Пользователь');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // --- Градиентная шапка профиля ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(AppColors.rCard + 4),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.solid,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          if (state.isPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '★ PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.userPhone.isNotEmpty
                            ? state.userPhone
                            : context.tr('Добавьте номер телефона'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: AppColors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Статистика ---
          Row(
            children: [
              _StatCard(
                icon: Icons.shopping_bag_outlined,
                value: '${state.orders.length}',
                label: context.tr('Заказы'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.favorite_border,
                value: '${state.favorites.length}',
                label: context.tr('Избранное'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.shopping_cart_outlined,
                value: '${state.cartCount}',
                label: context.tr('В корзине'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Premium-баннер ---
          _PremiumBanner(
            isPremium: state.isPremium,
            until: state.premiumUntil,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // --- Меню ---
          _MenuItem(
            icon: Icons.receipt_long_outlined,
            title: context.tr('Мои заказы'),
            subtitle: state.orders.isEmpty ? null : '${state.orders.length}',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          _MenuItem(
            icon: Icons.favorite_border,
            title: context.tr('Избранное'),
            subtitle: context.trp('{n} товаров', {'n': '${state.favorites.length}'}),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: context.tr('Настройки'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // --- Быстрый переключатель темы ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: c.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  state.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  size: 22,
                  color: AppColors.solid,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.tr('Тёмная тема'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                Switch(
                  value: state.isDark,
                  onChanged: state.setDark,
                  activeTrackColor: AppColors.solid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          _MenuItem(
            icon: Icons.logout_rounded,
            title: context.tr('Выйти'),
            isDestructive: true,
            onTap: () {
              state.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Баннер на профиле: вход в раздел Premium (или статус, если активен).
class _PremiumBanner extends StatelessWidget {
  final bool isPremium;
  final DateTime? until;
  final VoidCallback onTap;

  const _PremiumBanner({
    required this.isPremium,
    required this.until,
    required this.onTap,
  });

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = isPremium
        ? (until != null
            ? context.trp('Активен до {date}', {'date': _date(until!)})
            : context.tr('Активен'))
        : context.tr('Специальные цены на товары');
    return GestureDetector(
      onTap: onTap,
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
                color: Colors.white, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? context.tr('JUZUM Premium ★') : context.tr('Стать Premium'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: c.tint,
            borderRadius: BorderRadius.circular(AppColors.rCard),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.solid, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: c.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accent = isDestructive ? const Color(0xFFE5484D) : AppColors.solid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? accent : c.ink,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.solid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.solid,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 20, color: c.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
