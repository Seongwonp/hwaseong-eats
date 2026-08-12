class Restaurant {
  final int id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final String? category;
  final String? phone;
  final bool isKonapay;
  final bool isMobeom;
  final List<String> tags;
  final double? rating;
  final int reviewCount;

  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.category,
    this.phone,
    required this.isKonapay,
    required this.isMobeom,
    required this.tags,
    this.rating,
    this.reviewCount = 0,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'],
        name: json['name'],
        address: json['address'] ?? '',
        lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
        lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
        category: json['category'],
        phone: json['phone'],
        isKonapay: json['is_konapay'] ?? false,
        isMobeom: json['is_mobeom'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
        rating: json['avg_rating'] != null ? (json['avg_rating'] as num).toDouble() : null,
        reviewCount: json['review_count'] ?? 0,
      );
}
