class Restaurant {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final bool isHwaseongPay;
  final String source; // 모범음식점 | 착한가격 | 로컬푸드
  final List<String> tags; // 카공픽 | 10대픽 | 혼밥 | 가성비

  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    required this.isHwaseongPay,
    required this.source,
    required this.tags,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'],
        name: json['name'],
        address: json['address'] ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        category: json['category'] ?? '',
        isHwaseongPay: json['is_hwaseong_pay'] ?? false,
        source: json['source'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
      );
}
