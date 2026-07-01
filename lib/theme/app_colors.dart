import 'package:flutter/material.dart';

/// Адаптивная палитра — меняется между светлой и тёмной темой.
/// Берётся через `AppColors.of(context)` или `context.cs`.
class AppPalette {
  final Color ink; // основной текст
  final Color grey; // вторичный текст
  final Color line; // границы, разделители
  final Color tint; // фон блоков/инпутов
  final Color surface; // фон экрана
  final Color card; // фон карточек

  const AppPalette({
    required this.ink,
    required this.grey,
    required this.line,
    required this.tint,
    required this.surface,
    required this.card,
  });
}

class AppColors {
  // --- Бренд (одинаков в обеих темах) ---
  static const violet = Color(0xFFA21CF2); // основной акцент
  static const solid = Color(0xFF7A18E0); // плоский фиолетовый (кнопки)
  static const indigo = Color(0xFF340F87); // тёмный
  static const white = Color(0xFFFFFFFF); // текст/иконки на градиенте

  // Фирменный градиент 135° (сверху-слева → вниз-направо)
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA21CF2), Color(0xFF7314D9), Color(0xFF340F87)],
  );

  // --- Premium ---
  static const premium = Color(0xFF1E9E54); // премиум-цена / экономия
  static const premiumGold = Color(0xFFB8860B); // акцент бренда Premium
  // Золотой градиент для премиум-баннеров и бейджей
  static const premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6C453), Color(0xFFD9A21B), Color(0xFFB8860B)],
  );

  // Радиусы
  static const rCard = 18.0;
  static const rButton = 16.0;

  // --- Палитры ---
  static const light = AppPalette(
    ink: Color(0xFF160B3B),
    grey: Color(0xFF6E6788),
    line: Color(0xFFE7DEF6),
    tint: Color(0xFFF6F2FD),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    ink: Color(0xFFF3F0FA),
    grey: Color(0xFFA49CC0),
    line: Color(0xFF332B4D),
    tint: Color(0xFF241D3A),
    surface: Color(0xFF120D1F),
    card: Color(0xFF1C1530),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension AppColorsContext on BuildContext {
  /// Краткий доступ к палитре: `context.cs.ink`.
  AppPalette get cs => AppColors.of(this);
}
