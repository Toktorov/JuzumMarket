import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../l10n/l10n.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final favorites = context.watch<AppState>().favorites;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Избранное'))),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: c.line),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('В избранном пусто'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('Нажимайте ♡ на товарах,\nчтобы сохранить их здесь'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) => ProductCard(product: favorites[i]),
            ),
    );
  }
}
