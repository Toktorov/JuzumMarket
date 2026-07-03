import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/notification.dart';
import '../models/cart_item.dart';

/// Ошибка API с сообщением для пользователя.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Клиент REST API бэкенда JUZUM.
///
/// Продакшн-бэкенд (публичный HTTPS). Для локальной разработки по USB
/// можно временно поставить 'http://127.0.0.1:8000' + `adb reverse tcp:8000 tcp:8000`.
class ApiService {
  static const String baseUrl = 'https://juzum.bigbee.su';
  static const String apiUrl = '$baseUrl/api';
  static const _timeout = Duration(seconds: 8);

  final http.Client _client = http.Client();

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  /// Категории со всеми языками (переключение мгновенное на клиенте).
  Future<List<CategoryInfo>> fetchCategories() async {
    final res = await _client
        .get(Uri.parse('$apiUrl/categories/'))
        .timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] ?? data) as List;
    return results.map((c) => CategoryInfo.fromJson(c)).toList();
  }

  Future<List<Product>> fetchProducts() async {
    final res = await _client
        .get(Uri.parse('$apiUrl/products/'))
        .timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] ?? data) as List;
    return results.map((j) => Product.fromJson(j)).toList();
  }

  /// Вход по телефону и паролю. Возвращает {'phone', 'name'}.
  Future<Map<String, String>> login(String phone, String password) async {
    return _auth('login', {'phone': phone, 'password': password});
  }

  /// Регистрация: телефон, имя, email, пароль.
  Future<Map<String, String>> register(
      String phone, String name, String email, String password) async {
    return _auth('register', {
      'phone': phone,
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// Запрос кода сброса пароля на email.
  Future<void> forgotPassword(String email) async {
    await _simplePost('auth/forgot', {'email': email});
  }

  /// Сброс пароля по коду из письма.
  Future<void> resetPassword(
      String email, String code, String password) async {
    await _simplePost('auth/reset', {
      'email': email,
      'code': code,
      'password': password,
    });
  }

  Future<void> _simplePost(String path, Map<String, String> body) async {
    final res = await _client
        .post(
          Uri.parse('$apiUrl/$path/'),
          headers: _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      throw ApiException(
          (data is Map ? data['detail'] as String? : null) ?? 'Ошибка');
    }
  }

  Future<Map<String, String>> _auth(
      String path, Map<String, String> body) async {
    final res = await _client
        .post(
          Uri.parse('$apiUrl/auth/$path/'),
          headers: _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw ApiException(
          (data is Map ? data['detail'] as String? : null) ?? 'Ошибка');
    }
    return _customerMap(data, body);
  }

  /// Приводит ответ с покупателем к строковой карте для AppState.
  Map<String, String> _customerMap(dynamic data, [Map<String, String>? body]) {
    return {
      'phone': (data['phone'] as String?) ?? body?['phone'] ?? '',
      'name': (data['name'] as String?) ?? body?['name'] ?? '',
      'email': (data['email'] as String?) ?? body?['email'] ?? '',
      'is_premium': (data['is_premium'] == true).toString(),
      'premium_until': (data['premium_until'] as String?) ?? '',
    };
  }

  /// Разовая покупка Premium (навсегда).
  Future<Map<String, String>> subscribePremium(String phone) async {
    final res = await _client
        .post(
          Uri.parse('$apiUrl/auth/premium/'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone}),
        )
        .timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw ApiException(
          (data is Map ? data['detail'] as String? : null) ?? 'Ошибка');
    }
    return _customerMap(data);
  }

  /// Обновляет имя и email покупателя на сервере.
  Future<void> updateProfile(String phone, String name, String email) async {
    await _client
        .post(
          Uri.parse('$apiUrl/profile/'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone, 'name': name, 'email': email}),
        )
        .timeout(_timeout);
  }

  /// Создаёт заказ из корзины. [photoOf] — поиск фото товара по id.
  Future<Order> createOrder({
    required String phone,
    required String name,
    required DeliveryInfo delivery,
    required PaymentMethod payment,
    required List<CartItem> cart,
    required String Function(String productId) photoOf,
  }) async {
    final body = {
      'phone': phone,
      'name': name,
      'delivery_name': delivery.name,
      'delivery_phone': delivery.phone,
      'city': delivery.city,
      'address': delivery.address,
      'comment': delivery.comment,
      'payment': payment == PaymentMethod.online ? 'online' : 'cash',
      'items': cart
          .map((c) => {
                'product': int.tryParse(c.product.id) ?? c.product.id,
                'quantity': c.quantity,
                'options': c.optionIds,
              })
          .toList(),
    };
    final res = await _client
        .post(
          Uri.parse('$apiUrl/orders/'),
          headers: _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      throw Exception('Не удалось оформить заказ (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Order.fromJson(data, photoOf);
  }

  /// Похожие товары: та же категория, кроме текущего.
  Future<List<Product>> fetchSimilar(String category, String excludeId,
      {String lang = 'ru'}) async {
    final uri = Uri.parse('$apiUrl/products/').replace(queryParameters: {
      'category': category,
      'exclude': excludeId,
      'lang': lang,
    });
    final res = await _client.get(uri).timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] ?? data) as List;
    return results.map((j) => Product.fromJson(j)).toList();
  }

  Future<List<Review>> fetchReviews(String productId) async {
    final uri = Uri.parse('$apiUrl/reviews/')
        .replace(queryParameters: {'product': productId});
    final res = await _client.get(uri).timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] ?? data) as List;
    return results.map((j) => Review.fromJson(j)).toList();
  }

  Future<Review> addReview({
    required String productId,
    required String phone,
    required String name,
    required int rating,
    required String text,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$apiUrl/reviews/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'product': int.tryParse(productId) ?? productId,
            'phone': phone,
            'name': name,
            'rating': rating,
            'text': text,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      throw Exception('Не удалось отправить отзыв (${res.statusCode})');
    }
    return Review.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<ReviewReply> addReply({
    required int reviewId,
    required String phone,
    required String name,
    required String text,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$apiUrl/reviews/reply/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'review': reviewId,
            'phone': phone,
            'name': name,
            'text': text,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      throw Exception('Не удалось отправить ответ (${res.statusCode})');
    }
    return ReviewReply.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<List<AppNotification>> fetchNotifications(String phone) async {
    final uri = Uri.parse('$apiUrl/notifications/')
        .replace(queryParameters: {'phone': phone});
    final res = await _client.get(uri).timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] ?? data) as List;
    return results.map((j) => AppNotification.fromJson(j)).toList();
  }

  /// Отмечает уведомления прочитанными: одно (id) или все.
  Future<void> markNotificationsRead(String phone, {int? id}) async {
    await _client
        .post(
          Uri.parse('$apiUrl/notifications/read/'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone, if (id != null) 'id': id}),
        )
        .timeout(_timeout);
  }

  Future<List<Order>> fetchOrders(
    String phone,
    String Function(String productId) photoOf,
  ) async {
    final res = await _client
        .get(Uri.parse('$apiUrl/orders/?phone=${Uri.encodeComponent(phone)}'))
        .timeout(_timeout);
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] ?? data) as List;
    return results.map((j) => Order.fromJson(j, photoOf)).toList();
  }
}
