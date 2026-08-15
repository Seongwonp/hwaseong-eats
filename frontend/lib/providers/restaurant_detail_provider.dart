import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../models/review.dart';
import '../services/api_service.dart';

final restaurantDetailProvider =
    FutureProvider.autoDispose.family<Restaurant, int>((ref, restaurantId) async {
  final response = await ApiService().getRestaurant(restaurantId);
  return Restaurant.fromJson(response.data as Map<String, dynamic>);
});

final restaurantReviewsProvider =
    FutureProvider.autoDispose.family<ReviewPage, int>((ref, restaurantId) async {
  final response = await ApiService().getReviews(
    restaurantId: restaurantId,
    limit: 100,
  );
  final data = response.data as Map<String, dynamic>;
  final items = (data['items'] as List<dynamic>? ?? const [])
      .map((item) => Review.fromJson(item as Map<String, dynamic>))
      .toList();
  return ReviewPage(total: data['total'] as int? ?? items.length, items: items);
});
