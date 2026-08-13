import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../providers/festival_provider.dart';
import '../providers/restaurant_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/seasonal_banner.dart';
import '../widgets/restaurant_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // ignore: unused_field
  KakaoMapController? _mapController;

  static const _categoryItems = [
    ('음식점', Icons.restaurant),
    ('카페', Icons.local_cafe),
    ('편의점', Icons.store),
    ('대형마트', Icons.shopping_cart),
  ];

  List<Marker> _buildMarkers(List<Restaurant> restaurants) {
    return restaurants
        .where((r) => r.lat != null && r.lng != null)
        .map((r) => Marker(
              markerId: r.id.toString(),
              latLng: LatLng(r.lat!, r.lng!),
            ))
        .toList();
  }

  void _onMarkerTap(String markerId, LatLng latLng, int zoomLevel) {
    final filter = ref.read(filterProvider);
    final restaurants =
        ref.read(restaurantsFutureProvider(filter)).valueOrNull ?? [];
    final idx = restaurants.indexWhere((r) => r.id.toString() == markerId);
    if (idx == -1) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RestaurantBottomSheet(restaurant: restaurants[idx]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final restaurantsAsync = ref.watch(restaurantsFutureProvider(filter));
    final restaurants = restaurantsAsync.valueOrNull ?? [];
    final todayEvent = ref.watch(todayEventProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 카카오맵 풀스크린
          KakaoMap(
            onMapCreated: (c) => _mapController = c,
            onMarkerTap: _onMarkerTap,
            center: LatLng(37.1996, 126.8312),
            currentLevel: 8,
            markers: _buildMarkers(restaurants),
          ),

          // 하단 드래그 패널
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.12,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.38],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, -4))
                  ],
                ),
                child: Column(
                  children: [
                    // 핸들
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 6),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // 헤더: 지역명 + 화성페이 토글 버튼
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          context.hPad, 6, context.hPad, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '화성시',
                            style: TextStyle(
                              fontFamily: 'NotoSerifKR',
                              fontSize: context.fs(18),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                ref.read(filterProvider.notifier).update(
                                      (s) =>
                                          s.copyWith(isKonapay: !s.isKonapay),
                                    ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: filter.isKonapay
                                    ? AppColors.primary
                                    : Colors.white,
                                border: Border.all(
                                    color: AppColors.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '화성페이',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: filter.isKonapay
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF0F0F0)),

                    // 음식점 목록
                    Expanded(
                      child: restaurantsAsync.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : restaurantsAsync.hasError
                              ? _RestaurantLoadError(
                                  onRetry: () => ref.invalidate(
                                      restaurantsFutureProvider(filter)),
                                )
                              : restaurants.isEmpty
                                  ? const _EmptyListPlaceholder()
                                  : ListView.separated(
                                      controller: scrollController,
                                      padding:
                                          const EdgeInsets.only(bottom: 32),
                                      itemCount: restaurants.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                              height: 1,
                                              color: Color(0xFFF0F0F0)),
                                      itemBuilder: (ctx, i) =>
                                          _MapRestaurantCard(
                                              restaurant: restaurants[i]),
                                    ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 볏섬 로고 (맵 위 좌하단, 패널 바로 위)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.38 + 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6)
                ],
              ),
              child: const Text(
                '볏섬',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSerifKR',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // 상단 오버레이: 절기배너 + 검색바 + 카테고리 칩
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayEvent != null) SeasonalBanner(event: todayEvent),

                // 검색바
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(context.hPad, 10, context.hPad, 0),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '여기에 검색',
                            style: TextStyle(
                              fontSize: context.fs(14),
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 카테고리 칩 (수평 스크롤)
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: context.hPad),
                    itemCount: _categoryItems.length,
                    itemBuilder: (_, i) {
                      final (label, icon) = _categoryItems[i];
                      final selected = filter.category == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => ref.read(filterProvider.notifier).update(
                                (s) => selected
                                    ? s.copyWith(clearCategory: true)
                                    : s.copyWith(category: label),
                              ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color:
                                  selected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 15,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 맵 하단 패널용 음식점 카드
class _MapRestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;
  const _MapRestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);
    final isFav = favorites.contains(restaurant.id);

    return InkWell(
      onTap: () =>
          context.push('/restaurant/${restaurant.id}', extra: restaurant),
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 + 화성페이 배지 + 하트
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (restaurant.isKonapay)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.primary, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '화성 페이 가능',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      ref.read(favoriteProvider.notifier).toggle(restaurant.id),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color:
                          isFav ? AppColors.primary : const Color(0xFFCCCCCC),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // 주소
            Text(
              restaurant.address,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (restaurant.distanceKm != null || restaurant.rating != null) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  if (restaurant.distanceKm != null) ...[
                    const Icon(Icons.location_on,
                        size: 13, color: Color(0xFFBBBBBB)),
                    const SizedBox(width: 2),
                    Text(
                      '${restaurant.distanceKm!.toStringAsFixed(1)}km',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                  if (restaurant.distanceKm != null &&
                      restaurant.rating != null)
                    const SizedBox(width: 10),
                  if (restaurant.rating != null) ...[
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFFBB33)),
                    const SizedBox(width: 2),
                    Text(
                      '${restaurant.rating!.toStringAsFixed(1)} (${restaurant.reviewCount})',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyListPlaceholder extends StatelessWidget {
  const _EmptyListPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: Color(0xFFCCCCCC)),
          SizedBox(height: 8),
          Text('주변 음식점이 없어요',
              style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

class _RestaurantLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _RestaurantLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 8),
          const Text('음식점 정보를 불러오지 못했어요', style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
