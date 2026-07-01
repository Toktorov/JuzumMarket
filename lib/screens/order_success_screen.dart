import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/order.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final paid = order.isPaid;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: AppColors.white),
              ),
              const SizedBox(height: 24),
              Text(
                paid ? context.tr('Оплачено!') : context.tr('Заказ оформлен!'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                paid
                    ? context.tr('Оплата прошла успешно.\nМы готовим ваш заказ к отправке.')
                    : context.tr('Мы свяжемся с вами для подтверждения.\nОплата — наличными при получении.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: c.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.tint,
                  borderRadius: BorderRadius.circular(AppColors.rCard),
                ),
                child: Column(
                  children: [
                    _row(c, context.tr('Номер заказа'), order.id),
                    const SizedBox(height: 10),
                    _row(c, context.tr('Сумма'), '${order.grandTotal.toInt()} ${context.tr('сом')}'),
                    const SizedBox(height: 10),
                    _row(c, context.tr('Оплата'), context.tr(order.payment.label)),
                    const SizedBox(height: 10),
                    _row(c, context.tr('Статус'), context.tr(order.status.label)),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: context.tr('Мои заказы'),
                gradient: true,
                onPressed: () {
                  Navigator.popUntil(context, (r) => r.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                child: Text(
                  context.tr('Вернуться на главную'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppPalette c, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: c.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}
