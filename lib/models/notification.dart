class AppNotification {
  final int id;
  final String kind; // reply | order | discount | promo
  final String kindDisplay;
  final String title;
  final String body;
  final String? productId; // для перехода на товар
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.kind,
    required this.kindDisplay,
    required this.title,
    required this.body,
    required this.productId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      kind: json['kind'] as String? ?? 'promo',
      kindDisplay: json['kind_display'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      productId: json['product_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}
