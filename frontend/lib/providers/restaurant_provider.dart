import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class FilterState {
  final bool isKonapay;
  final bool isMobeom;
  final String? category; // 음식점 | 카페 | 편의점 | 대형마트 | null=전체

  const FilterState(
      {this.isKonapay = false, this.isMobeom = false, this.category});

  FilterState copyWith(
      {bool? isKonapay,
      bool? isMobeom,
      String? category,
      bool clearCategory = false}) {
    return FilterState(
      isKonapay: isKonapay ?? this.isKonapay,
      isMobeom: isMobeom ?? this.isMobeom,
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FilterState &&
      other.isKonapay == isKonapay &&
      other.isMobeom == isMobeom &&
      other.category == category;

  @override
  int get hashCode => Object.hash(isKonapay, isMobeom, category);
}

final filterProvider = StateProvider<FilterState>((ref) => const FilterState());

String? _toApiCategoryGroup(String? category) {
  return switch (category) {
    '음식점' => 'restaurant',
    '카페' => 'cafe',
    '편의점' => 'convenience',
    '대형마트' => 'mart',
    _ => null,
  };
}

final selectedRestaurantProvider = StateProvider<Restaurant?>((ref) => null);

// 지도 bounds 타입 (named record)
typedef MapBounds = ({double lat, double lng, double radiusKm});

// 지도 bounds 상태 - 화성시청 좌표 + 반경 2km 기본값
// MapScreen.initState에서 GPS 위치로 덮어쓰고, 사용자가 명시적으로 검색할 때만 업데이트
final mapBoundsProvider = StateProvider<MapBounds?>((ref) => (
      lat: 37.1996,
      lng: 126.8312,
      radiusKm: 2.0,
    ));

// filterProvider + mapBoundsProvider 양쪽을 watch하는 통합 지도용 provider.
// Riverpod이 의존성 변경 시 이전 Future를 자동 폐기하므로 race condition 없음.
const _kMapQueryLimit = 30;

final mapRestaurantsProvider =
    FutureProvider<({List<Restaurant> restaurants, int total})>((ref) async {
  final filter = ref.watch(filterProvider);
  final bounds = ref.watch(mapBoundsProvider);

  final res = await ApiService().getRestaurants(
    isKonapay: filter.isKonapay ? true : null,
    isMobeom: filter.isMobeom ? true : null,
    categoryGroup: _toApiCategoryGroup(filter.category),
    lat: bounds?.lat,
    lng: bounds?.lng,
    radiusKm: bounds?.radiusKm,
    limit: _kMapQueryLimit,
  );
  final data = res.data as Map<String, dynamic>;
  final total = data['total'] as int? ?? 0;
  final items = data['items'] as List<dynamic>? ?? [];
  final restaurants =
      items.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  return (restaurants: restaurants, total: total);
});
