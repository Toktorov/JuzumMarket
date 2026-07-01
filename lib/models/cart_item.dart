import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  /// Выбранные варианты (по одному значению на группу).
  final List<ProductOptionValue> options;

  CartItem({required this.product, this.quantity = 1, this.options = const []});

  /// Надбавка к цене за выбранные варианты.
  double get optionsDelta =>
      options.fold(0.0, (sum, o) => sum + o.priceDelta);

  /// id выбранных вариантов — уходят на сервер при оформлении.
  List<int> get optionIds => options.map((o) => o.id).toList();

  /// Подпись вариантов, напр. «Чёрный · 46 мм».
  String get optionsLabel => options.map((o) => o.value).join(' · ');

  /// Фото строки: фото выбранного варианта (цвет), иначе — фото товара.
  String get displayImage {
    for (final o in options) {
      if (o.photo.isNotEmpty) return o.photo;
    }
    return product.imageUrl;
  }

  /// Ключ строки корзины: товар + набор вариантов.
  String get key {
    final ids = optionIds.toList()..sort();
    return '${product.id}#${ids.join(',')}';
  }

  double get total => product.price * quantity;
}
