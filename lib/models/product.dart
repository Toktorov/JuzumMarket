import '../l10n/l10n.dart';

/// Одно значение варианта (например «Чёрный», «46 мм»).
class ProductOptionValue {
  final int id;
  final String value;
  final double priceDelta;
  final String photo;

  const ProductOptionValue({
    required this.id,
    required this.value,
    this.priceDelta = 0,
    this.photo = '',
  });

  bool get hasPhoto => photo.isNotEmpty;

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) =>
      ProductOptionValue(
        id: (json['id'] as num).toInt(),
        value: json['value'] as String? ?? '',
        priceDelta: (json['price_delta'] as num?)?.toDouble() ?? 0,
        photo: json['photo'] as String? ?? '',
      );
}

/// Группа вариантов (например «Цвет», «Модель»).
class ProductOptionGroup {
  final String group;
  final List<ProductOptionValue> options;

  const ProductOptionGroup({required this.group, required this.options});

  /// Есть ли у группы фото у вариантов (тогда выбор идёт по галерее).
  bool get hasPhotos => options.any((o) => o.hasPhoto);

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) =>
      ProductOptionGroup(
        group: json['group'] as String? ?? '',
        options: ((json['options'] as List?) ?? [])
            .map((o) => ProductOptionValue.fromJson(o))
            .toList(),
      );
}

/// Категория с переводами (мгновенное переключение языка на клиенте).
class CategoryInfo {
  final String nameRu;
  final String nameKy;
  final String nameEn;

  const CategoryInfo({
    required this.nameRu,
    this.nameKy = '',
    this.nameEn = '',
  });

  /// Отображаемое название на текущем языке.
  String get label => pick3(nameRu, nameKy, nameEn);

  /// Стабильный ключ (русское имя) — для фильтрации, не зависит от языка.
  String get key => nameRu;

  factory CategoryInfo.fromJson(Map<String, dynamic> json) => CategoryInfo(
        nameRu: json['name'] as String? ?? '',
        nameKy: json['name_ky'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
      );
}

class Product {
  final String id;
  final String nameRu;
  final String nameKy;
  final String nameEn;
  final double price;
  final double? oldPrice;
  final double? premiumPrice;
  final int premiumDiscountPercent;
  final int discountPercent;
  final double rating;
  final int reviewsCount;
  final String categoryRu;
  final String categoryKy;
  final String categoryEn;
  final String descriptionRu;
  final String descriptionKy;
  final String descriptionEn;
  final String imageUrl;
  final List<ProductOptionGroup> optionGroups;
  bool isFavorite;

  Product({
    required this.id,
    required String name,
    String nameKy = '',
    String nameEn = '',
    required this.price,
    this.oldPrice,
    this.premiumPrice,
    this.premiumDiscountPercent = 0,
    this.discountPercent = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    required String category,
    String categoryKy = '',
    String categoryEn = '',
    required String description,
    String descriptionKy = '',
    String descriptionEn = '',
    required this.imageUrl,
    this.optionGroups = const [],
    this.isFavorite = false,
  })  : nameRu = name,
        nameKy = nameKy,
        nameEn = nameEn,
        categoryRu = category,
        categoryKy = categoryKy,
        categoryEn = categoryEn,
        descriptionRu = description,
        descriptionKy = descriptionKy,
        descriptionEn = descriptionEn;

  /// Локализованные поля (мгновенно меняются при смене языка).
  String get name => pick3(nameRu, nameKy, nameEn);
  String get category => pick3(categoryRu, categoryKy, categoryEn);
  String get description =>
      pick3(descriptionRu, descriptionKy, descriptionEn);

  /// Стабильный ключ категории (русское имя) — для фильтрации.
  String get categoryKey => categoryRu;

  bool get hasOptions => optionGroups.isNotEmpty;

  /// Группа, выбираемая листанием фото (напр. «Цвет» с фотками на цвет).
  ProductOptionGroup? get galleryGroup {
    for (final g in optionGroups) {
      if (g.hasPhotos) return g;
    }
    return null;
  }

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Есть ли отдельная (более низкая) цена для премиум-покупателей.
  bool get hasPremiumPrice => premiumPrice != null && premiumPrice! < price;

  /// Цена с учётом премиум-статуса покупателя.
  double priceFor(bool isPremium) =>
      (isPremium && hasPremiumPrice) ? premiumPrice! : price;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      nameKy: json['name_ky'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (json['old_price'] as num?)?.toDouble(),
      premiumPrice: (json['premium_price'] as num?)?.toDouble(),
      premiumDiscountPercent:
          (json['premium_discount_percent'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      categoryKy: json['category_ky'] as String? ?? '',
      categoryEn: json['category_en'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionKy: json['description_ky'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      imageUrl: json['photo'] as String? ?? '',
      optionGroups: ((json['option_groups'] as List?) ?? [])
          .map((g) => ProductOptionGroup.fromJson(g))
          .toList(),
    );
  }
}
