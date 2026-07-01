import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';
import 'auth_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // Если сессия сохранена — сразу в приложение, иначе на экран входа.
      final loggedIn = context.read<AppState>().isLoggedIn;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => loggedIn ? const MainScreen() : const AuthScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo glyph
                Image.asset(
                  'assets/logo/juzum_lockup_v_white.png',
                  width: 180,
                  errorBuilder: (_, __, ___) => const Text(
                    'JUZUM',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('маркетплейс для всех'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
