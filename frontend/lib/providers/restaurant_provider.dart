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

final mockRestaurants = [
  const Restaurant(
    id: 1,
    name: '화성순두부찌게 동탄점',
    address: '경기 화성시 효행구 봉담읍 하우로 51',
    lat: 37.2010,
    lng: 127.0720,
    category: '한식',
    isKonapay: true,
    isMobeom: true,
    tags: ['가성비', '10대픽'],
    rating: 4.6,
    reviewCount: 122,
  ),
  const Restaurant(
    id: 2,
    name: '카페테라이아',
    address: '경기 화성시 효행구 봉담읍 하우로 72',
    lat: 37.1990,
    lng: 127.0690,
    category: '카페',
    isKonapay: true,
    isMobeom: false,
    tags: ['카공픽'],
    rating: 4.7,
    reviewCount: 95,
  ),
  const Restaurant(
    id: 3,
    name: '제부도 조개구이',
    address: '화성시 서신면 제부리 78',
    lat: 37.1890,
    lng: 126.6340,
    category: '해산물',
    isKonapay: false,
    isMobeom: true,
    tags: [],
    rating: 4.4,
    reviewCount: 58,
  ),
  const Restaurant(
    id: 4,
    name: '바베큐 앤 칩스',
    address: '화성시 병점동 234',
    lat: 37.2200,
    lng: 127.0350,
    category: '양식',
    isKonapay: true,
    isMobeom: false,
    tags: ['가성비'],
    rating: 4.2,
    reviewCount: 11,
  ),
  const Restaurant(
    id: 5,
    name: '이탈리안 브런치',
    address: '화성시 향남읍 발안리 56',
    lat: 37.1740,
    lng: 126.9810,
    category: '브런치',
    isKonapay: false,
    isMobeom: false,
    tags: ['카공픽', '혼밥'],
    rating: 4.5,
    reviewCount: 37,
  ),
  const Restaurant(
    id: 6,
    name: '송산 포도밭 한정식',
    address: '화성시 서신면 전곡리 123',
    lat: 37.1530,
    lng: 126.6890,
    category: '한식',
    isKonapay: true,
    isMobeom: true,
    tags: ['가성비'],
    rating: 4.8,
    reviewCount: 203,
  ),
];

// 새로 오픈한 가게 (reviewCount 적은 것 기준)
final newRestaurants =
    mockRestaurants.where((r) => r.reviewCount < 40).toList();

bool _matchesCategory(Restaurant r, String? category) {
  if (category == null) return true;
  const cafeCategories = ['카페', '커피숍', '디저트카페'];
  const convenienceCategories = ['편의점'];
  const martCategories = ['대형마트', '마트', '슈퍼마켓'];
  switch (category) {
    case '카페':
      return cafeCategories.contains(r.category);
    case '편의점':
      return convenienceCategories.contains(r.category);
    case '대형마트':
      return martCategories.contains(r.category);
    case '음식점': // 카페/편의점/마트 제외한 나머지 전부 = 음식점
      return !cafeCategories.contains(r.category) &&
          !convenienceCategories.contains(r.category) &&
          !martCategories.contains(r.category);
    default:
      return true;
  }
}

String? _toApiCategoryGroup(String? category) {
  return switch (category) {
    '음식점' => 'restaurant',
    '카페' => 'cafe',
    '편의점' => 'convenience',
    '대형마트' => 'mart',
    _ => null,
  };
}

final restaurantProvider = Provider<List<Restaurant>>((ref) {
  final filter = ref.watch(filterProvider);
  return mockRestaurants.where((r) {
    if (filter.isKonapay && !r.isKonapay) return false;
    if (filter.isMobeom && !r.isMobeom) return false;
    if (!_matchesCategory(r, filter.category)) return false;
    return true;
  }).toList();
});

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
