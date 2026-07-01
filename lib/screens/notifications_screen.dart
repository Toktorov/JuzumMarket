import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../l10n/l10n.dart';
import '../models/notification.dart';
import '../theme/app_colors.dart';
import 'product_screen.dart';
import 'orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppState>().loadNotifications(),
    );
  }

  static String _ago(BuildContext context, DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return context.tr('только что');
    if (diff.inMinutes < 60) {
      return context.trp('{n} мин назад', {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return context.trp('{n} ч назад', {'n': '${diff.inHours}'});
    }
    if (diff.inDays < 7) {
      return context.trp('{n} дн назад', {'n': '${diff.inDays}'});
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  IconData _icon(String kind) => switch (kind) {
        'reply' => Icons.reply_rounded,
        'order' => Icons.local_shipping_rounded,
        'discount' => Icons.sell_rounded,
        _ => Icons.campaign_rounded,
      };

  Future<void> _open(AppNotification n) async {
    final state = context.read<AppState>();
    await state.markNotificationRead(n);
    if (!mounted) return;

    if (n.productId != null) {
      final product = state.productById(n.productId!);
      if (product != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
        );
        return;
      }
    }
    if (n.kind == 'order') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final items = state.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Уведомления')),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: state.markAllNotificationsRead,
              child: Text(
                context.tr('Прочитать все'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.solid,
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: c.line),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('Уведомлений пока нет'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                return GestureDetector(
                  onTap: () => _open(n),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead ? c.card : c.tint,
                      borderRadius: BorderRadius.circular(AppColors.rCard),
                      border: Border.all(
                        color: n.isRead ? c.line : AppColors.solid,
                        width: n.isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.solid.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_icon(n.kind),
                              size: 20, color: AppColors.solid),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: c.ink,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.solid,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              if (n.body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: c.grey,
                                      height: 1.35),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                _ago(context, n.createdAt),
                                style: TextStyle(fontSize: 11, color: c.grey),
                              ),
                            ],
                          ),
                        ),
                        if (n.productId != null || n.kind == 'order')
                          Icon(Icons.chevron_right, size: 20, color: c.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
