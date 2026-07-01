import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/order.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import 'product_screen.dart';

/// Детальный просмотр заказа со статусом-«путём» (трекинг доставки).
class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  // Этапы «пути» заказа (кроме отмены).
  static const _path = [
    OrderStatus.processing,
    OrderStatus.confirmed,
    OrderStatus.delivering,
    OrderStatus.delivered,
  ];

  static const _stepTitle = {
    OrderStatus.processing: 'Заказ оформлен',
    OrderStatus.confirmed: 'Подтверждён',
    OrderStatus.delivering: 'В доставке',
    OrderStatus.delivered: 'Доставлен',
  };

  static const _stepIcon = {
    OrderStatus.processing: Icons.receipt_long_rounded,
    OrderStatus.confirmed: Icons.inventory_2_rounded,
    OrderStatus.delivering: Icons.local_shipping_rounded,
    OrderStatus.delivered: Icons.check_circle_rounded,
  };

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.trp('Заказ {id}', {'id': order.id})),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Статус-«путь» ---
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppColors.rCard),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Статус заказа'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 16),
                if (order.status == OrderStatus.cancelled)
                  _cancelledPath(context, c)
                else
                  _statusPath(context, c),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Состав заказа ---
          _Section(context.tr('Состав заказа'), c: c),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppColors.rCard),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < order.lines.length; i++) ...[
                  if (i > 0) Divider(color: c.line, height: 1),
                  _lineTile(context, c, order.lines[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Доставка ---
          _Section(context.tr('Данные доставки'), c: c),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppColors.rCard),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                _row(c, context.tr('Имя получателя'), order.delivery.name),
                _row(c, context.tr('Телефон'), order.delivery.phone),
                _row(c, context.tr('Город'), order.delivery.city),
                _row(c, context.tr('Адрес (улица, дом, кв.)'),
                    order.delivery.address),
                _row(c, context.tr('Оплата'),
                    context.tr(order.payment.label)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Итоги ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.tint,
              borderRadius: BorderRadius.circular(AppColors.rCard),
            ),
            child: Column(
              children: [
                _row(c, context.tr('Товары ({n} шт.)')
                    .replaceAll('{n}', '${order.itemCount}'),
                    '${order.itemsTotal.toInt()} ${context.tr('сом')}'),
                _row(
                    c,
                    context.tr('Доставка'),
                    order.deliveryFee == 0
                        ? context.tr('Бесплатно')
                        : '${order.deliveryFee.toInt()} ${context.tr('сом')}'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('Итого'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      '${order.grandTotal.toInt()} ${context.tr('сом')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.solid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formatDate(order.createdAt),
              style: TextStyle(fontSize: 12, color: c.grey),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statusPath(BuildContext context, AppPalette c) {
    final current = _path.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < _path.length; i++)
          _stepRow(
            context,
            c,
            icon: _stepIcon[_path[i]]!,
            title: context.tr(_stepTitle[_path[i]]!),
            done: i < current,
            current: i == current,
            isLast: i == _path.length - 1,
          ),
      ],
    );
  }

  Widget _cancelledPath(BuildContext context, AppPalette c) {
    return Column(
      children: [
        _stepRow(context, c,
            icon: Icons.receipt_long_rounded,
            title: context.tr('Заказ оформлен'),
            done: true,
            current: false,
            isLast: false),
        _stepRow(context, c,
            icon: Icons.cancel_rounded,
            title: context.tr('Отменён'),
            done: false,
            current: true,
            isLast: true,
            cancelled: true),
      ],
    );
  }

  /// Один шаг «пути»: кружок + линия + подпись.
  Widget _stepRow(
    BuildContext context,
    AppPalette c, {
    required IconData icon,
    required String title,
    required bool done,
    required bool current,
    required bool isLast,
    bool cancelled = false,
  }) {
    final active = done || current;
    final accent = cancelled ? const Color(0xFFE5484D) : AppColors.solid;
    final reachedColor = cancelled ? const Color(0xFFE5484D) : AppColors.solid;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кружок + вертикальная линия
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? reachedColor : c.tint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? reachedColor : c.line,
                    width: 2,
                  ),
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  done ? Icons.check_rounded : icon,
                  size: 18,
                  color: active ? Colors.white : c.grey,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? reachedColor : c.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Подпись
          Padding(
            padding: EdgeInsets.only(top: 6, bottom: isLast ? 6 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: active ? c.ink : c.grey,
                  ),
                ),
                if (current && !cancelled)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      context.tr('Текущий статус'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineTile(BuildContext context, AppPalette c, OrderLine line) {
    final product = context.read<AppState>().productById(line.productId);
    final tile = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: line.imageUrl.isEmpty
                ? Container(
                    width: 56, height: 56, color: c.tint,
                    child: Icon(Icons.image, color: c.grey))
                : Image.network(
                    line.imageUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 56, height: 56, color: c.tint,
                        child: Icon(Icons.image, color: c.grey)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.price.toInt()} ${context.tr('сом')} × ${line.quantity}',
                  style: TextStyle(fontSize: 13, color: c.grey),
                ),
              ],
            ),
          ),
          Text(
            '${line.total.toInt()} ${context.tr('сом')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.solid,
            ),
          ),
        ],
      ),
    );

    if (product == null) return tile;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
      ),
      child: tile,
    );
  }

  Widget _row(AppPalette c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: c.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final AppPalette c;
  const _Section(this.title, {required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: c.ink,
        ),
      ),
    );
  }
}
