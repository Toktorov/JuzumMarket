class ReviewReply {
  final int id;
  final String authorName;
  final bool isSeller;
  final String text;
  final DateTime createdAt;

  const ReviewReply({
    required this.id,
    required this.authorName,
    required this.isSeller,
    required this.text,
    required this.createdAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    return ReviewReply(
      id: (json['id'] as num).toInt(),
      authorName: json['author_name'] as String? ?? 'Аноним',
      isSeller: json['is_seller'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

class Review {
  final int id;
  final String authorName;
  final int rating;
  final String text;
  final DateTime createdAt;
  final List<ReviewReply> replies;

  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.replies = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as num).toInt(),
      authorName: json['author_name'] as String? ?? 'Аноним',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      replies: (json['replies'] as List? ?? [])
          .map((r) => ReviewReply.fromJson(r))
          .toList(),
    );
  }
}
