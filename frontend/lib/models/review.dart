class Review {
  final int id;
  final int restaurantId;
  final String nickname;
  final List<String> tags;
  final int? rating;
  final String? comment;
  final bool isHwaseongCertified;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.restaurantId,
    required this.nickname,
    required this.tags,
    required this.rating,
    required this.comment,
    required this.isHwaseongCertified,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        restaurantId: json['restaurant_id'] as int,
        nickname: json['nickname'] as String,
        tags: (json['tags'] as List<dynamic>? ?? const [])
            .map((tag) => tag as String)
            .toList(),
        rating: json['rating'] as int?,
        comment: json['comment'] as String?,
        isHwaseongCertified: json['is_hwaseong_certified'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ReviewPage {
  final int total;
  final List<Review> items;

  const ReviewPage({required this.total, required this.items});
}
