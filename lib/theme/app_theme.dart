import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = GoogleFonts.nunitoTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.solid,
        onPrimary: AppColors.white,
        secondary: AppColors.violet,
        onSecondary: AppColors.white,
        error: const Color(0xFFE5484D),
        onError: AppColors.white,
        surface: p.surface,
        onSurface: p.ink,
      ),
      textTheme: base.apply(bodyColor: p.ink, displayColor: p.ink).copyWith(
            headlineLarge:
                GoogleFonts.nunito(fontWeight: FontWeight.w800, color: p.ink),
            headlineMedium:
                GoogleFonts.nunito(fontWeight: FontWeight.w800, color: p.ink),
            titleLarge:
                GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.ink),
            titleMedium:
                GoogleFonts.nunito(fontWeight: FontWeight.w600, color: p.ink),
            bodyLarge:
                GoogleFonts.nunito(fontWeight: FontWeight.w500, color: p.ink),
            bodyMedium:
                GoogleFonts.nunito(fontWeight: FontWeight.w500, color: p.ink),
            bodySmall:
                GoogleFonts.nunito(fontWeight: FontWeight.w400, color: p.grey),
            labelLarge: GoogleFonts.nunito(
                fontWeight: FontWeight.w600, color: AppColors.white),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: AppColors.violet,
        unselectedItemColor: p.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      dividerColor: p.line,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.solid,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.rButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.tint,
        prefixIconColor: p.grey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.rButton),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.rButton),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.rButton),
          borderSide: const BorderSide(color: AppColors.solid, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w500, color: p.grey),
      ),
    );
  }
}
