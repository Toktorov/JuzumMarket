import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/order.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Обновляем список заказов с сервера при открытии.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppState>().loadOrders(),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final orders = context.watch<AppState>().orders;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Мои заказы'))),
      body: orders.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final o = orders[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: o),
                    ),
                  ),
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(AppColors.rCard),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.trp('Заказ {id}', {'id': '${o.id}'}),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          _StatusBadge(status: o.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(o.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: c.grey),
                      ),
                      const SizedBox(height: 12),
                      // Превью товаров
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            for (final line in o.lines.take(4))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: line.imageUrl.isEmpty
                                      ? Container(
                                          width: 48,
                                          height: 48,
                                          color: c.tint,
                                          child: Icon(Icons.image,
                                              size: 20, color: c.grey),
                                        )
                                      : Image.network(
                                          line.imageUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 48,
                                            height: 48,
                                            color: c.tint,
                                            child: Icon(Icons.image,
                                                size: 20, color: c.grey),
                                          ),
                                        ),
                                ),
                              ),
                            if (o.lines.length > 4)
                              Text(
                                '+${o.lines.length - 4}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: c.line, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.trp('{count} тов. · {payment}', {
                              'count': '${o.itemCount}',
                              'payment': context.tr(o.payment.label)
                            }),
                            style: TextStyle(
                                fontSize: 12, color: c.grey),
                          ),
                          Text(
                            context.trp(
                                '{v} сом', {'v': '${o.grandTotal.toInt()}'}),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.solid,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.tr(status.label),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.solid,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: c.line),
          const SizedBox(height: 16),
          Text(
            context.tr('Заказов пока нет'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Оформите первый заказ в каталоге'),
            style: TextStyle(fontSize: 14, color: c.grey),
          ),
        ],
      ),
    );
  }
}
