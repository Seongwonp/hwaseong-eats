import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';

// 필터 상태
class FilterState {
  final bool hwaseongPay;
  final String? tag; // 카공픽 | 10대픽 | 혼밥 | 가성비

  const FilterState({this.hwaseongPay = false, this.tag});

  FilterState copyWith({bool? hwaseongPay, String? tag, bool clearTag = false}) {
    return FilterState(
      hwaseongPay: hwaseongPay ?? this.hwaseongPay,
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }
}

final filterProvider = StateProvider<FilterState>((ref) => const FilterState());

// 목 데이터 (API 연결 전까지 사용)
final mockRestaurants = [
  const Restaurant(
    id: 1, name: '송산 포도밭 한정식', address: '화성시 서신면 전곡리 123',
    lat: 37.1530, lng: 126.6890, category: '한식',
    isHwaseongPay: true, source: '모범음식점', tags: ['가성비'],
  ),
  const Restaurant(
    id: 2, name: '동탄 삼계탕 전문점', address: '화성시 동탄면 방교리 45',
    lat: 37.2010, lng: 127.0720, category: '한식',
    isHwaseongPay: true, source: '착한가격', tags: ['혼밥', '가성비'],
  ),
  const Restaurant(
    id: 3, name: '제부도 조개구이', address: '화성시 서신면 제부리 78',
    lat: 37.1890, lng: 126.6340, category: '해산물',
    isHwaseongPay: false, source: '모범음식점', tags: [],
  ),
  const Restaurant(
    id: 4, name: '병점 카페 라운지', address: '화성시 병점동 234',
    lat: 37.2200, lng: 127.0350, category: '카페',
    isHwaseongPay: true, source: '착한가격', tags: ['카공픽', '10대픽'],
  ),
  const Restaurant(
    id: 5, name: '로컬푸드 직매장 식당', address: '화성시 향남읍 발안리 56',
    lat: 37.1740, lng: 126.9810, category: '한식',
    isHwaseongPay: false, source: '로컬푸드', tags: ['가성비'],
  ),
];

final restaurantProvider = Provider<List<Restaurant>>((ref) {
  final filter = ref.watch(filterProvider);
  return mockRestaurants.where((r) {
    if (filter.hwaseongPay && !r.isHwaseongPay) return false;
    if (filter.tag != null && !r.tags.contains(filter.tag)) return false;
    return true;
  }).toList();
});

final selectedRestaurantProvider = StateProvider<Restaurant?>((ref) => null);
