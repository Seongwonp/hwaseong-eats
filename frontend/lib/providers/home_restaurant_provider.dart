import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../services/api_service.dart';

List<Restaurant> _parseRestaurants(Object? rawData) {
  final data = rawData as Map<String, dynamic>;
  return (data['items'] as List<dynamic>? ?? const [])
      .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
      .toList();
}

final homeKonapayRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final response = await ApiService().getRestaurants(
    isKonapay: true,
    // 아래 모범음식점 섹션과 같은 가게가 반복되지 않도록 역할을 나눈다.
    isMobeom: false,
    limit: 2,
  );
  return _parseRestaurants(response.data);
});

final homeMobeomRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final response = await ApiService().getRestaurants(
    isMobeom: true,
    limit: 2,
  );
  return _parseRestaurants(response.data);
});
