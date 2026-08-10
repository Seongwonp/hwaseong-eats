import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  KakaoMapController? _mapController;
  final SeasonalEvent? _todayEvent = getTodayEvent();

  Set<Marker> _buildMarkers(List restaurants) {
    return restaurants.map((r) {
      Color markerColor = AppColors.markerDefault;
      if (r.isHwaseongPay) markerColor = AppColors.markerPay;

      // TODO: 절기 기간이면 markerColor = AppColors.markerSeasonal
      // TODO: 축제 주변이면 markerColor = AppColors.markerFestival

      return Marker(
        markerId: r.id.toString(),
        latLng: LatLng(r.lat, r.lng),
        markerImageSrc: '',
        // 마커 색상은 커스텀 마커 이미지로 교체 필요
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 카카오맵
          KakaoMap(
            onMapCreated: (controller) => _mapController = controller,
            onMarkerTap: _onMarkerTap,
            center: const LatLng(37.1996, 126.8312), // 화성시 중심
            currentLevel: 8,
            markers: _buildMarkers(restaurants),
          ),

          // 상단 오버레이
          SafeArea(
            child: Column(
              children: [
                // 절기 배너 (오늘 해당하는 경우만)
                if (_todayEvent != null) SeasonalBanner(event: _todayEvent!),

                // 필터 칩
                Container(
                  color: AppColors.background.withOpacity(0.95),
                  child: const FilterChipRow(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
