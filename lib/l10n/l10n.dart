import 'package:flutter/widgets.dart';
import 'translations.dart';

/// Текущий язык приложения (глобально, обновляется в AppState.setLang).
/// Используется данными товаров/категорий для мгновенного переключения
/// без повторной загрузки с сервера.
String appLang = 'ru';

/// Выбирает значение по текущему языку с фолбэком на русский.
String pick3(String ru, String ky, String en) {
  if (appLang == 'ky') return ky.isNotEmpty ? ky : ru;
  if (appLang == 'en') return en.isNotEmpty ? en : ru;
  return ru;
}

/// Языки интерфейса. Русский — исходный (ключи переводов на русском).
const supportedLangs = ['ky', 'ru', 'en'];

const langNames = {
  'ky': 'Кыргызча',
  'ru': 'Русский',
  'en': 'English',
};

/// InheritedWidget с текущим языком. Размещается НАД MaterialApp,
/// поэтому смена языка перестраивает все виджеты, вызвавшие `context.tr`,
/// без сброса навигации.
class AppLang extends InheritedWidget {
  final String lang;
  const AppLang({super.key, required this.lang, required super.child});

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLang>()?.lang ?? 'ru';

  @override
  bool updateShouldNotify(AppLang oldWidget) => oldWidget.lang != lang;
}

extension L10nX on BuildContext {
  /// Переводит русскую строку [ru] на текущий язык.
  /// Русский — исходный ключ; при отсутствии перевода возвращает [ru].
  String tr(String ru) {
    final lang = AppLang.of(this);
    if (lang == 'ru') return ru;
    final map = lang == 'ky' ? kyTranslations : enTranslations;
    return map[ru] ?? ru;
  }

  /// Перевод с подстановкой: `context.trp('{n} товаров', {'n': '5'})`.
  String trp(String ru, Map<String, String> params) {
    var result = tr(ru);
    params.forEach((k, v) => result = result.replaceAll('{$k}', v));
    return result;
  }
}
