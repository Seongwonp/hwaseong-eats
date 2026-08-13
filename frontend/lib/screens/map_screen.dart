import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

const _kDefaultLat = 37.1996;
const _kDefaultLng = 126.8312;
const _kSearchRadiusKm = 2.0;
const _kMaxDisplayCount = 30;
const _kTooFarZoomLevel = 10;
const _kMovedThreshold = 0.005; // ≈ 500m

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  KakaoMapController? _mapController;

  // GPS 초기화는 위젯 수명 동안 단 한 번만 실행
  bool _locationInitialized = false;

  LatLng _pendingCenter = LatLng(_kDefaultLat, _kDefaultLng);
  int _zoomLevel = 8;
  bool _showSearchHere = false;
  bool _isLocating = false;

  // 마커 리스트 메모이제이션 — restaurants 참조가 바뀔 때만 재생성해
  // KakaoMap이 동일 내용을 다른 참조로 감지해 내부 업데이트하는 걸 방지
  List<Restaurant> _markerSource = const [];
  List<Marker> _cachedMarkers = const [];

  static const _categoryItems = [
    ('음식점', Icons.restaurant),
    ('카페', Icons.local_cafe),
    ('편의점', Icons.store),
    ('대형마트', Icons.shopping_cart),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // guard: 탭 재진입으로 위젯이 재생성돼도 GPS는 한 번만 실행
      if (_locationInitialized || !mounted) return;
      _locationInitialized = true;
      _initLocation();
    });
  }

  // --- 위치 획득 ---

  Future<void> _initLocation() async {
    final pos = await _fetchPosition();
    // await 후 dispose 됐을 수 있으므로 반드시 체크
    if (!mounted) return;

    final lat = pos?.latitude ?? _kDefaultLat;
    final lng = pos?.longitude ?? _kDefaultLng;

    _pendingCenter = LatLng(lat, lng);
    _commitSearch(lat, lng);

    if (!mounted) return;
    _mapController?.setCenter(LatLng(lat, lng));
  }

  // denied / deniedForever 분기, 서비스 꺼짐, 타임아웃 모두 null 반환
  Future<Position?> _fetchPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted || !serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (!mounted) return null;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return null;
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  // --- 검색 커밋 ---

  // mapBoundsProvider 갱신 → mapRestaurantsProvider 자동 재실행.
  // setState는 _showSearchHere가 실제로 변할 때만 호출.
  void _commitSearch(double lat, double lng) {
    if (!mounted) return;
    ref.read(mapBoundsProvider.notifier).state = (
      lat: lat,
      lng: lng,
      radiusKm: _kSearchRadiusKm,
    );
    if (_showSearchHere) {
      setState(() => _showSearchHere = false);
    }
  }

  // --- 카메라 콜백 ---

  // 카메라 상태만 기록; API 호출은 절대 여기서 하지 않음.
  // 값이 실제로 바뀌었을 때만 setState → KakaoMap 재빌드/onCameraIdle 루프 방지.
  void _onCameraIdle(LatLng center, int zoomLevel) {
    if (!mounted) return;

    final searched = ref.read(mapBoundsProvider);
    final lastLat = searched?.lat ?? _kDefaultLat;
    final lastLng = searched?.lng ?? _kDefaultLng;

    final moved = (center.latitude - lastLat).abs() > _kMovedThreshold ||
        (center.longitude - lastLng).abs() > _kMovedThreshold;
    final newShowSearch = moved && zoomLevel <= _kTooFarZoomLevel;

    // 바뀐 게 없으면 rebuild 생략 (연속 발화 방어)
    final samePos =
        (center.latitude - _pendingCenter.latitude).abs() < 1e-7 &&
        (center.longitude - _pendingCenter.longitude).abs() < 1e-7;
    if (samePos && zoomLevel == _zoomLevel && newShowSearch == _showSearchHere) {
      return;
    }

    setState(() {
      _pendingCenter = center;
      _zoomLevel = zoomLevel;
      _showSearchHere = newShowSearch;
    });
  }

  // --- 버튼 핸들러 ---

  void _onSearchHere() {
    _commitSearch(_pendingCenter.latitude, _pendingCenter.longitude);
  }

  Future<void> _onMyLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    final pos = await _fetchPosition();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치를 가져올 수 없어요')),
      );
      return;
    }

    final center = LatLng(pos.latitude, pos.longitude);
    _mapController?.setCenter(center);
    _pendingCenter = center;
    _commitSearch(pos.latitude, pos.longitude);
  }

  // --- 마커 ---

  // restaurants 참조가 같으면 이전 리스트 재사용 → KakaoMap 불필요 업데이트 방지
  List<Marker> _getMarkers(List<Restaurant> restaurants) {
    if (identical(restaurants, _markerSource)) return _cachedMarkers;
    _markerSource = restaurants;
    _cachedMarkers = restaurants
        .where((r) => r.lat != null && r.lng != null)
        .map((r) => Marker(
              markerId: r.id.toString(),
              latLng: LatLng(r.lat!, r.lng!),
            ))
        .toList();
    return _cachedMarkers;
  }

  void _onMarkerTap(String markerId, LatLng latLng, int zoomLevel) {
    final restaurants =
        ref.read(mapRestaurantsProvider).valueOrNull?.restaurants ?? [];
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

  // --- build ---

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final mapAsync = ref.watch(mapRestaurantsProvider);
    final restaurants = mapAsync.valueOrNull?.restaurants ?? [];
    final total = mapAsync.valueOrNull?.total ?? 0;
    final todayEvent = ref.watch(todayEventProvider).valueOrNull;

    final isTooFarOut = _zoomLevel > _kTooFarZoomLevel;
    final isOverLimit = total > _kMaxDisplayCount;
    final panelOffset = MediaQuery.of(context).size.height * 0.38 + 12;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── 카카오맵 ──────────────────────────────────────
          KakaoMap(
            onMapCreated: (c) => _mapController = c,
            onMarkerTap: _onMarkerTap,
            onCameraIdle: _onCameraIdle,
            center: LatLng(_kDefaultLat, _kDefaultLng),
            currentLevel: 8,
            markers: _getMarkers(restaurants), // 메모이제이션된 리스트
          ),

          // ── 하단 드래그 패널 ──────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.12,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.38],
            builder: (ctx, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    )
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

                    // 헤더
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          context.hPad, 6, context.hPad, 10),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                              if (!mapAsync.isLoading &&
                                  !mapAsync.hasError) ...[
                                const SizedBox(height: 2),
                                Text(
                                  isOverLimit
                                      ? '가까운 음식점 ${_kMaxDisplayCount}개를 표시하고 있어요'
                                      : restaurants.isEmpty
                                          ? '주변 음식점을 찾을 수 없어요'
                                          : '${restaurants.length}개 음식점',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF999999)),
                                ),
                              ],
                            ],
                          ),
                          _KonapayToggle(
                            active: filter.isKonapay,
                            onTap: () => ref
                                .read(filterProvider.notifier)
                                .update((s) =>
                                    s.copyWith(isKonapay: !s.isKonapay)),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF0F0F0)),

                    // 음식점 목록
                    Expanded(
                      child: mapAsync.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : mapAsync.hasError
                              ? _ErrorView(
                                  onRetry: () => ref
                                      .invalidate(mapRestaurantsProvider),
                                )
                              : restaurants.isEmpty
                                  ? const _EmptyView()
                                  : ListView.separated(
                                      controller: scrollController,
                                      padding: const EdgeInsets.only(
                                          bottom: 32),
                                      itemCount: restaurants.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                              height: 1,
                                              color: Color(0xFFF0F0F0)),
                                      itemBuilder: (_, i) =>
                                          _MapRestaurantCard(
                                              restaurant: restaurants[i]),
                                    ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── 볏섬 로고 ─────────────────────────────────────
          Positioned(
            bottom: panelOffset,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                  )
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

          // ── 내 위치 버튼 ───────────────────────────────────
          Positioned(
            bottom: panelOffset,
            right: 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isLocating ? null : _onMyLocation,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _isLocating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary),
                        )
                      : const Icon(Icons.my_location,
                          color: AppColors.primary, size: 22),
                ),
              ),
            ),
          ),

          // ── 상단 오버레이 ──────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todayEvent != null) SeasonalBanner(event: todayEvent),

                // 검색바
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.hPad, 10, context.hPad, 0),
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
                            color:
                                Colors.black.withValues(alpha: 0.12),
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

                // 카테고리 칩
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        EdgeInsets.symmetric(horizontal: context.hPad),
                    itemCount: _categoryItems.length,
                    itemBuilder: (_, i) {
                      final (label, icon) = _categoryItems[i];
                      final selected = filter.category == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              ref.read(filterProvider.notifier).update(
                                    (s) => selected
                                        ? s.copyWith(clearCategory: true)
                                        : s.copyWith(category: label),
                                  ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 15,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPrimary),
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

                const SizedBox(height: 8),

                // "이 지역에서 검색" / "지도를 확대해 주세요"
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isTooFarOut
                        ? _MapHintChip(
                            key: const ValueKey('zoom'),
                            icon: Icons.zoom_in,
                            label: '지도를 확대해 주세요',
                            onTap: null,
                          )
                        : _showSearchHere
                            ? _MapHintChip(
                                key: const ValueKey('search'),
                                icon: Icons.search,
                                label: '이 지역에서 검색',
                                isPrimary: true,
                                onTap: _onSearchHere,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('none')),
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

// ── 서브 위젯들 ────────────────────────────────────────────────────────────

class _KonapayToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _KonapayToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '화성페이',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MapHintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _MapHintChip({
    super.key,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.primary : Colors.white;
    final fgColor =
        isPrimary ? Colors.white : const Color(0xFF555555);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;
  const _MapRestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav =
        ref.watch(favoriteProvider).contains(restaurant.id);
    return InkWell(
      onTap: () => context.push(
          '/restaurant/${restaurant.id}', extra: restaurant),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.hPad, 14, context.hPad, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            border: Border.all(
                                color: AppColors.primary, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '화성페이',
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
                  onTap: () => ref
                      .read(favoriteProvider.notifier)
                      .toggle(restaurant.id),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      isFav
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFav
                          ? AppColors.primary
                          : const Color(0xFFCCCCCC),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.address,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF999999)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (restaurant.distanceKm != null ||
                restaurant.rating != null) ...[
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
          SizedBox(height: 4),
          Text('지도를 이동해 다른 지역을 검색해보세요',
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 8),
          const Text('음식점 정보를 불러오지 못했어요',
              style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
