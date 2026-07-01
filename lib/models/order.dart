/// Снимок позиции заказа (с сервера; не зависит от корзины после оформления).
class OrderLine {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  const OrderLine({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
  });

  double get total => price * quantity;
}

/// Данные доставки, которые покупатель вводит при оформлении.
class DeliveryInfo {
  final String name;
  final String phone;
  final String city;
  final String address;
  final String comment;

  const DeliveryInfo({
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    this.comment = '',
  });
}

enum PaymentMethod { online, cash }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.online => 'Онлайн-оплата картой',
        PaymentMethod.cash => 'Наличными при получении',
      };
}

enum OrderStatus { processing, confirmed, delivering, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.processing => 'В обработке',
        OrderStatus.confirmed => 'Подтверждён',
        OrderStatus.delivering => 'В доставке',
        OrderStatus.delivered => 'Доставлен',
        OrderStatus.cancelled => 'Отменён',
      };
}

class Order {
  final String id; // номер заказа, напр. JZ-1001
  final List<OrderLine> lines;
  final DeliveryInfo delivery;
  final PaymentMethod payment;
  final bool isPaid;
  final double itemsTotal;
  final double deliveryFee;
  final DateTime createdAt;
  final OrderStatus status;

  Order({
    required this.id,
    required this.lines,
    required this.delivery,
    required this.payment,
    required this.isPaid,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.createdAt,
    this.status = OrderStatus.processing,
  });

  double get grandTotal => itemsTotal + deliveryFee;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  /// Разбор заказа из ответа API. [photoOf] — поиск фото товара по id.
  factory Order.fromJson(
    Map<String, dynamic> json,
    String Function(String productId) photoOf,
  ) {
    final items = (json['items'] as List? ?? []).map((it) {
      final pid = it['product']?.toString() ?? '';
      // Фото выбранного варианта (снимок с сервера), иначе — фото товара.
      final snapshot = it['photo'] as String? ?? '';
      return OrderLine(
        productId: pid,
        productName: it['product_name'] as String? ?? '',
        price: (it['price'] as num?)?.toDouble() ?? 0,
        quantity: (it['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: snapshot.isNotEmpty ? snapshot : photoOf(pid),
      );
    }).toList();

    return Order(
      id: json['number'] as String? ?? 'JZ-${json['id']}',
      lines: items,
      delivery: DeliveryInfo(
        name: json['delivery_name'] as String? ?? '',
        phone: json['delivery_phone'] as String? ?? '',
        city: json['city'] as String? ?? '',
        address: json['address'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
      ),
      payment: (json['payment'] == 'online')
          ? PaymentMethod.online
          : PaymentMethod.cash,
      isPaid: json['is_paid'] as bool? ?? false,
      itemsTotal: (json['items_total'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      status: _statusFrom(json['status'] as String?),
    );
  }

  static OrderStatus _statusFrom(String? s) {
    return switch (s) {
      'confirmed' => OrderStatus.confirmed,
      'delivering' => OrderStatus.delivering,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.processing,
    };
  }
}
