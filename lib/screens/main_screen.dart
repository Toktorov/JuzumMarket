import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    CatalogScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<AppState>().cartCount;
    final c = AppColors.of(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: c.line, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: context.tr('Главная'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              label: context.tr('Каталог'),
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: AppColors.violet,
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: context.tr('Корзина'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: context.tr('Профиль'),
            ),
          ],
        ),
      ),
    );
  }
}
