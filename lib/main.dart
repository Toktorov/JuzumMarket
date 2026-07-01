import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_state.dart';
import 'theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const JuzumApp(),
    ),
  );
}

class JuzumApp extends StatelessWidget {
  const JuzumApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppLang(
      lang: state.lang,
      child: MaterialApp(
        title: 'JUZUM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: state.themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
