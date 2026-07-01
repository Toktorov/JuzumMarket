import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import '../widgets/primary_button.dart';
import 'auth_screen.dart';

/// Разовая цена Premium (примерная — потом поменяете в одном месте).
const int kPremiumPrice = 990;

const _benefits = [
  ('local_offer_rounded', 'Специальные цены',
      'Сниженные цены на товары по всему каталогу — только для Premium.'),
  ('savings_rounded', 'Экономия на каждой покупке',
      'Чем больше покупаете — тем больше экономите с премиум-ценами.'),
  ('workspace_premium_rounded', 'Статус навсегда',
      'Оплата один раз — доступ к премиум-ценам остаётся навсегда.'),
];

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await state.subscribePremium();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Premium активирован! Приятных покупок ★')),
          backgroundColor: AppColors.premium,
        ),
      );
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('Не удалось оформить')}: $e'),
          backgroundColor: const Color(0xFFE5484D),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final active = state.isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('JUZUM Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // --- Hero ---
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(AppColors.rCard + 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    size: 56, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'JUZUM Premium',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  active
                      ? context.tr('Premium активен')
                      : context.tr('Специальные цены на товары — навсегда'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // --- Преимущества ---
          Text(
            context.tr('Что входит'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final b in _benefits) _benefitTile(c, b),
          const SizedBox(height: 14),

          if (active)
            // Уже премиум.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.premium.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppColors.rCard),
                border: Border.all(
                    color: AppColors.premium.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppColors.premium, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('Premium активен. Вы платите специальные '
                          'цены по всему каталогу.'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // --- Разовая цена ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.tint,
                borderRadius: BorderRadius.circular(AppColors.rCard),
                border: Border.all(
                    color: AppColors.premiumGold.withValues(alpha: 0.5),
                    width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    context.tr('Разовая оплата'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$kPremiumPrice ${context.tr('сом')}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('доступ навсегда'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.premiumGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              text: _busy
                  ? context.tr('Оформляем…')
                  : '${context.tr('Купить Premium')} — $kPremiumPrice ${context.tr('сом')}',
              gradient: true,
              onPressed: _busy ? null : _buy,
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('Оплата один раз. Доступ к премиум-ценам остаётся '
                  'навсегда.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _benefitTile(AppPalette c, (String, String, String) b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(AppColors.rCard),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.premiumGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(b.$1), color: AppColors.premiumGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(b.$2),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(b.$3),
                  style: TextStyle(
                    fontSize: 13,
                    color: c.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String name) {
    switch (name) {
      case 'local_offer_rounded':
        return Icons.local_offer_rounded;
      case 'savings_rounded':
        return Icons.savings_rounded;
      case 'workspace_premium_rounded':
      default:
        return Icons.workspace_premium_rounded;
    }
  }
}
