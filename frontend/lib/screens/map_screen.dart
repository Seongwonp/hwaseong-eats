import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/seasonal_banner.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/restaurant_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // ignore: unused_field — 추후 지도 이동/레벨 조작에 사용
  KakaoMapController? _mapController;
  final SeasonalEvent? _todayEvent = getTodayEvent();

  Set<Marker> _buildMarkers(List restaurants) {
    return restaurants.map((r) {
      // TODO: 커스텀 마커 이미지로 색상별 분기 처리
      // 화성페이: markerPay / 절기: markerSeasonal / 축제: markerFestival
      return Marker(
        markerId: r.id.toString(),
        latLng: LatLng(r.lat, r.lng),
        markerImageSrc: '',
      );
    }).toSet();
  }

  void _onMarkerTap(String markerId, LatLng latLng) {
    final restaurants = ref.read(restaurantProvider);
    final restaurant = restaurants.firstWhere((r) => r.id.toString() == markerId);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RestaurantBottomSheet(restaurant: restaurant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantProvider);
    final todayEvent = _todayEvent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          KakaoMap(
            onMapCreated: (controller) => _mapController = controller,
            onMarkerTap: _onMarkerTap,
            center: const LatLng(37.1996, 126.8312),
            currentLevel: 8,
            markers: _buildMarkers(restaurants),
          ),

          // 상단 오버레이
          SafeArea(
            child: Column(
              children: [
                if (todayEvent != null) SeasonalBanner(event: todayEvent),
                Container(
                  color: AppColors.background.withValues(alpha: 0.95),
                  child: const FilterChipRow(),
                ),
              ],
            ),
          ),

          // 검색 버튼 (우상단)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.search, size: 22, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // 바텀 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (i) {
          if (i == 1) context.push('/festival');
          if (i == 2) context.push('/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.celebration_outlined), activeIcon: Icon(Icons.celebration), label: '축제·절기'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}
