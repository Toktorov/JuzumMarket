import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'product_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final cart = state.cart;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              context.tr('Корзина'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Content
          if (cart.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 64, color: c.line),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('Корзина пуста'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('Добавьте товары из каталога'),
                      style: TextStyle(
                        fontSize: 14,
                        color: c.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cart.length,
                separatorBuilder: (_, __) => Divider(
                  color: c.line,
                  height: 1,
                ),
                itemBuilder: (_, i) {
                  final item = cart[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Image — тап открывает товар
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductScreen(product: item.product),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.displayImage,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: c.tint,
                                child: Icon(Icons.image,
                                    color: c.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductScreen(product: item.product),
                                  ),
                                ),
                                child: Text(
                                  item.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              if (item.optionsLabel.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.optionsLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: c.grey),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${state.lineUnitPrice(item).toInt()} ${context.tr('сом')}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: state.isPremium &&
                                              item.product.hasPremiumPrice
                                          ? AppColors.premium
                                          : AppColors.solid,
                                    ),
                                  ),
                                  if (state.isPremium &&
                                      item.product.hasPremiumPrice) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${(item.product.price + item.optionsDelta).toInt()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: c.grey,
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Quantity controls
                              Row(
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove,
                                    onTap: () => state.updateQuantity(
                                        item.key,
                                        item.quantity - 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: c.ink,
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add,
                                    onTap: () => state.updateQuantity(
                                        item.key,
                                        item.quantity + 1),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => state.removeFromCart(
                                        item.key),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: c.grey,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Похожие товары (на этапе оформления)
            Builder(builder: (context) {
              final cartIds = cart.map((e) => e.product.id).toSet();
              final recs = state.recommended
                  .where((p) => !cartIds.contains(p.id))
                  .take(8)
                  .toList();
              if (recs.isEmpty) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      context.tr('Похожие товары'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 248,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: recs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 150,
                        child: ProductCard(product: recs[i]),
                      ),
                    ),
                  ),
                ],
              );
            }),
            // Bottom: total + order button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(
                  top: BorderSide(color: c.line),
                ),
              ),
              child: Column(
                children: [
                  if (state.isPremium && state.cartSavings > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                size: 16, color: AppColors.premium),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('Скидка Premium'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.premium,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '−${state.cartSavings.toInt()} ${context.tr('сом')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.premium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('Итого:'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        '${state.cartTotal.toInt()} ${context.tr('сом')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solid,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: context.tr('Оформить заказ'),
                    gradient: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: c.ink),
      ),
    );
  }
}
