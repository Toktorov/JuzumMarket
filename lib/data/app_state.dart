import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/notification.dart';
import 'api.dart';
import 'mock_products.dart' as mock;
import '../l10n/l10n.dart';

class AppState extends ChangeNotifier {
  final ApiService _api = ApiService();

  AppState() {
    _restoreSession();
    loadCatalog();
  }

  // --- Auth ---
  bool _isLoggedIn = false;
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
  bool _isPremium = false;
  DateTime? _premiumUntil;
  bool _sessionRestored = false;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  bool get sessionRestored => _sessionRestored;

  /// Активен ли премиум прямо сейчас (с учётом срока действия).
  bool get isPremium =>
      _isPremium &&
      (_premiumUntil == null || _premiumUntil!.isAfter(DateTime.now()));
  DateTime? get premiumUntil => _premiumUntil;

  /// Восстанавливает сохранённую сессию и тему при запуске.
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dark') ?? false) _themeMode = ThemeMode.dark;
    _lang = prefs.getString('lang') ?? 'ru';
    appLang = _lang;
    final phone = prefs.getString('phone') ?? '';
    final name = prefs.getString('name') ?? '';
    if ((prefs.getBool('loggedIn') ?? false) && phone.isNotEmpty) {
      _isLoggedIn = true;
      _userPhone = phone;
      _userName = name;
      _userEmail = prefs.getString('email') ?? '';
      _isPremium = prefs.getBool('isPremium') ?? false;
      final until = prefs.getString('premiumUntil') ?? '';
      _premiumUntil = until.isEmpty ? null : DateTime.tryParse(until);
      loadOrders();
      loadNotifications();
    }
    _sessionRestored = true;
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', _isLoggedIn);
    await prefs.setString('phone', _userPhone);
    await prefs.setString('name', _userName);
    await prefs.setString('email', _userEmail);
    await prefs.setBool('isPremium', _isPremium);
    await prefs.setString(
        'premiumUntil', _premiumUntil?.toIso8601String() ?? '');
  }

  /// Вход по телефону через API. При недоступности сервера — локально.
  /// Вход по телефону и паролю. Бросает ApiException при неверных данных.
  Future<void> login(String phone, String password) async {
    final result = await _api.login(phone, password);
    _applyAuth(result, phone, '');
  }

  /// Регистрация: имя, телефон, email, пароль.
  Future<void> register(
      String name, String phone, String email, String password) async {
    final result = await _api.register(phone, name, email, password);
    _applyAuth(result, phone, name);
  }

  /// Запрос кода сброса пароля на email.
  Future<void> forgotPassword(String email) => _api.forgotPassword(email);

  /// Сброс пароля по коду.
  Future<void> resetPassword(String email, String code, String password) =>
      _api.resetPassword(email, code, password);

  Future<void> _applyAuth(
      Map<String, String> result, String phone, String name) async {
    _userPhone = (result['phone'] ?? '').isNotEmpty ? result['phone']! : phone;
    _userName = (result['name'] ?? '').isNotEmpty ? result['name']! : name;
    _userEmail = result['email'] ?? '';
    _applyPremium(result);
    _isLoggedIn = true;
    await _saveSession();
    notifyListeners();
    loadOrders();
    loadNotifications();
  }

  void _applyPremium(Map<String, String> result) {
    _isPremium = result['is_premium'] == 'true';
    final until = result['premium_until'] ?? '';
    _premiumUntil = until.isEmpty ? null : DateTime.tryParse(until);
  }

  /// Разовая покупка Premium через API (навсегда).
  Future<void> subscribePremium() async {
    final result = await _api.subscribePremium(_userPhone);
    _applyPremium(result);
    notifyListeners();
    await _saveSession();
    loadNotifications();
  }

  /// Цена товара с учётом премиум-статуса текущего пользователя.
  double priceOf(Product product) => product.priceFor(isPremium);

  /// Сохраняет профиль локально и синхронизирует имя и email с сервером.
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    _userName = name;
    _userPhone = phone;
    if (email != null) _userEmail = email;
    notifyListeners();
    await _saveSession();
    try {
      await _api.updateProfile(_userPhone, name, _userEmail);
    } catch (_) {
      // офлайн — синхронизируется позже
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _userPhone = '';
    _userEmail = '';
    _isPremium = false;
    _premiumUntil = null;
    _cart.clear();
    _orders.clear();
    _notifications.clear();
    _lastDelivery = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('phone');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('isPremium');
    await prefs.remove('premiumUntil');
  }

  // --- Язык интерфейса ('ru' | 'ky' | 'en') ---
  String _lang = 'ru';
  String get lang => _lang;

  void setLang(String lang) {
    if (lang == _lang) return;
    _lang = lang;
    appLang = lang; // товары/категории берут язык отсюда — мгновенно
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString('lang', lang));
  }

  // --- Тема ---
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void setDark(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool('dark', dark));
  }

  void toggleTheme() => setDark(!isDark);

  // --- Настройки (память сессии) ---
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;

  void setPushEnabled(bool v) {
    _pushEnabled = v;
    notifyListeners();
  }

  void setEmailEnabled(bool v) {
    _emailEnabled = v;
    notifyListeners();
  }

  // --- Каталог (с сервера) ---
  List<Product> _products = [];
  List<CategoryInfo> _categories = [];
  bool _catalogLoading = false;
  bool _offline = false;

  List<Product> get products => _products;

  /// Категории с переводами (для чипов/кружков с ключом и языком).
  List<CategoryInfo> get categoryList => _categories;

  /// Названия категорий на текущем языке (для отображения).
  List<String> get categories => _categories.map((c) => c.label).toList();
  bool get catalogLoading => _catalogLoading;
  bool get offline => _offline;

  final Map<String, Product> _productsById = {};

  String _photoOf(String productId) =>
      _productsById[productId]?.imageUrl ?? '';

  Future<void> loadCatalog() async {
    _catalogLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchCategories(),
        _api.fetchProducts(),
      ]);
      _categories = results[0] as List<CategoryInfo>;
      _products = results[1] as List<Product>;
      _offline = false;
    } catch (_) {
      // Нет связи с сервером — показываем демо-данные (только русский).
      _categories =
          mock.categories.map((n) => CategoryInfo(nameRu: n)).toList();
      _products = List<Product>.from(mock.mockProducts);
      _offline = true;
    }
    _productsById
      ..clear()
      ..addEntries(_products.map((p) => MapEntry(p.id, p)));
    _catalogLoading = false;
    notifyListeners();
  }

  List<Product> get favorites =>
      _products.where((p) => p.isFavorite).toList();

  void toggleFavorite(Product product) {
    product.isFavorite = !product.isFavorite;
    notifyListeners();
  }

  /// Фильтр по КЛЮЧУ категории (русское имя) — не зависит от языка.
  List<Product> getByCategory(String categoryKey) {
    if (categoryKey == 'Все') return _products;
    return _products.where((p) => p.categoryKey == categoryKey).toList();
  }

  List<Product> search(String query) {
    final q = query.toLowerCase();
    // Ищем по всем языкам, чтобы находилось независимо от текущего.
    return _products
        .where((p) =>
            p.nameRu.toLowerCase().contains(q) ||
            p.nameKy.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.categoryRu.toLowerCase().contains(q) ||
            p.categoryKy.toLowerCase().contains(q) ||
            p.categoryEn.toLowerCase().contains(q))
        .toList();
  }

  // --- Рекомендации по интересам ---
  final List<String> _recentSearches = [];
  String? _interestCategoryKey; // ключ категории (не зависит от языка)

  bool get hasInterest =>
      _interestCategoryKey != null || _recentSearches.isNotEmpty;

  /// Запоминает поисковый запрос и выводит «интересную» категорию.
  void recordSearch(String query) {
    final q = query.trim();
    if (q.length < 2) return;
    _recentSearches.remove(q);
    _recentSearches.add(q);
    final matches = search(q);
    if (matches.isNotEmpty) _interestCategoryKey = matches.first.categoryKey;
  }

  /// Запоминает категорию открытого товара (по ключу).
  void recordViewCategory(String categoryKey) {
    if (categoryKey.isNotEmpty) _interestCategoryKey = categoryKey;
  }

  /// Подборка «для вас»: товары интересной категории / по последнему поиску.
  List<Product> get recommended {
    if (_interestCategoryKey != null) {
      final inCat = _products
          .where((p) => p.categoryKey == _interestCategoryKey)
          .toList();
      if (inCat.isNotEmpty) return inCat;
    }
    if (_recentSearches.isNotEmpty) {
      final res = search(_recentSearches.last);
      if (res.isNotEmpty) return res;
    }
    return _products.take(6).toList();
  }

  // --- Похожие товары и отзывы ---
  Future<List<Product>> similarTo(Product product) async {
    // Локально (мгновенно, без сети и без рассинхрона языка).
    return _products
        .where((p) =>
            p.categoryKey == product.categoryKey && p.id != product.id)
        .toList();
  }

  Product? productById(String id) => _productsById[id];

  Future<List<Review>> reviewsFor(String productId) =>
      _api.fetchReviews(productId);

  // --- Уведомления ---
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    if (_userPhone.isEmpty) return;
    try {
      final list = await _api.fetchNotifications(_userPhone);
      _notifications
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // оставляем как есть
    }
  }

  Future<void> markNotificationRead(AppNotification n) async {
    if (n.isRead) return;
    n.isRead = true;
    notifyListeners();
    try {
      await _api.markNotificationsRead(_userPhone, id: n.id);
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _api.markNotificationsRead(_userPhone);
    } catch (_) {}
  }

  Future<Review> addReview(String productId, int rating, String text) =>
      _api.addReview(
        productId: productId,
        phone: _userPhone,
        name: _userName,
        rating: rating,
        text: text,
      );

  Future<ReviewReply> addReply(int reviewId, String text) => _api.addReply(
        reviewId: reviewId,
        phone: _userPhone,
        name: _userName,
        text: text,
      );

  // --- Корзина (локально) ---
  final List<CartItem> _cart = [];

  List<CartItem> get cart => _cart;

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  /// Цена единицы товара в строке: премиум-цена + надбавка за варианты.
  double lineUnitPrice(CartItem item) =>
      priceOf(item.product) + item.optionsDelta;

  /// Сумма строки корзины.
  double lineTotal(CartItem item) => lineUnitPrice(item) * item.quantity;

  double get cartTotal =>
      _cart.fold(0.0, (sum, item) => sum + lineTotal(item));

  /// Сколько премиум экономит на текущей корзине (0 если не премиум).
  double get cartSavings => _cart.fold(
      0.0,
      (sum, item) =>
          sum + (item.product.price - priceOf(item.product)) * item.quantity);

  void addToCart(Product product,
      {List<ProductOptionValue> options = const []}) {
    final item = CartItem(product: product, options: options);
    final idx = _cart.indexWhere((c) => c.key == item.key);
    if (idx >= 0) {
      _cart[idx].quantity++;
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String key) {
    _cart.removeWhere((c) => c.key == key);
    notifyListeners();
  }

  void updateQuantity(String key, int quantity) {
    final idx = _cart.indexWhere((c) => c.key == key);
    if (idx >= 0) {
      if (quantity <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // --- Заказы (с сервера) ---
  final List<Order> _orders = [];
  DeliveryInfo? _lastDelivery;

  List<Order> get orders => List.unmodifiable(_orders);
  DeliveryInfo? get lastDelivery => _lastDelivery;

  static const double deliveryFee = 150; // фикс. стоимость доставки, сом
  static const double freeDeliveryFrom = 3000; // бесплатно от этой суммы

  double get currentDeliveryFee =>
      cartTotal >= freeDeliveryFrom ? 0 : deliveryFee;

  Future<void> loadOrders() async {
    if (_userPhone.isEmpty) return;
    try {
      final list = await _api.fetchOrders(_userPhone, _photoOf);
      _orders
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (_) {
      // оставляем как есть
    }
  }

  /// Оформляет заказ через API из текущей корзины и очищает её.
  Future<Order> placeOrder({
    required DeliveryInfo delivery,
    required PaymentMethod payment,
  }) async {
    final order = await _api.createOrder(
      phone: _userPhone,
      name: _userName,
      delivery: delivery,
      payment: payment,
      cart: _cart,
      photoOf: _photoOf,
    );
    _lastDelivery = delivery;
    _cart.clear();
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
