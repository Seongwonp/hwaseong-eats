import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../models/seasonal_event.dart';
import '../providers/auth_provider.dart';
import '../providers/festival_provider.dart';
import '../providers/home_restaurant_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/home_restaurant_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final konapayRestaurants = ref.watch(homeKonapayRestaurantsProvider);
    final mobeomRestaurants = ref.watch(homeMobeomRestaurantsProvider);
    final todayEventAsync = ref.watch(todayEventProvider);
    final festivalsAsync = ref.watch(festivalsProvider);

    final SeasonalEvent? upcomingEvent =
        festivalsAsync.valueOrNull?.isNotEmpty == true
            ? festivalsAsync.value!.first
            : todayEventAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 헤더 ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 0),
                child: auth.isLoggedIn
                    ? _LoggedInHeader(
                        nickname: auth.nickname ?? '사용자',
                      )
                    : _LoggedOutHeader(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── 화성페이 가맹점 ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '화성페이 가맹점',
                          style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(filterProvider.notifier).state =
                                const FilterState(
                              isKonapay: true,
                            );
                            context.go('/map');
                          },
                          child: Text(
                            '지도에서 보기 >',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _RestaurantSectionCard(
                      restaurants: konapayRestaurants,
                      emptyMessage: '표시할 화성페이 가맹점이 없어요.',
                      leadingKeyword: '화성페이',
                      onRetry: () => ref.invalidate(
                        homeKonapayRestaurantsProvider,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── 모범음식점 ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '화성시 모범음식점',
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RestaurantSectionCard(
                      restaurants: mobeomRestaurants,
                      emptyMessage: '표시할 모범음식점이 없어요.',
                      leadingKeyword: '모범음식점',
                      onRetry: () => ref.invalidate(
                        homeMobeomRestaurantsProvider,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── 화성 먹거리 행사 ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '화성 먹거리 행사',
                          style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/calendar'),
                          child: Text(
                            '전체 보기 >',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    upcomingEvent != null
                        ? _EventBanner(event: upcomingEvent)
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('현재 진행 중인 행사가 없어요',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ),
                          ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── 식사평 남기기 (로그인 상태만) ─────────────
            if (auth.isLoggedIn)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.hPad),
                  child: _ReviewBanner(),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }
}

// ─── 헤더 위젯들 ──────────────────────────────────────────────────────

class _LoggedOutHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요,',
          style: TextStyle(
            fontSize: context.fs(13),
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => context.push('/login'),
          child: Text(
            '로그인 해주세요.',
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: context.fs(24),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoggedInHeader extends StatelessWidget {
  final String nickname;
  const _LoggedInHeader({required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요,',
          style: TextStyle(
            fontSize: context.fs(13),
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$nickname님',
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: context.fs(22),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── 식사평 남기기 배너 ───────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rate_review_outlined,
                size: 26, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          // 텍스트
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '식사평 남기기',
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '오늘 다녀온 가게의\n식사평을 남겨보세요',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          // 버튼
          ElevatedButton(
            onPressed: () => context.go('/map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('작성하기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── 공통 흰 카드 컨테이너 ──────────────────────────────────────────

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RestaurantSectionCard extends StatelessWidget {
  final AsyncValue<List<Restaurant>> restaurants;
  final String emptyMessage;
  final String leadingKeyword;
  final VoidCallback onRetry;

  const _RestaurantSectionCard({
    required this.restaurants,
    required this.emptyMessage,
    required this.leadingKeyword,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: restaurants.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Text('음식점 정보를 불러오지 못했어요.'),
              const SizedBox(height: 6),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
        data: (items) => items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFF0F0F0),
                ),
                itemBuilder: (_, index) => HomeRestaurantCard(
                  restaurant: items[index],
                  leadingKeywords: [leadingKeyword],
                ),
              ),
      ),
    );
  }
}

// ─── 행사 배너 ────────────────────────────────────────────────────────

class _EventBanner extends StatelessWidget {
  final SeasonalEvent event;
  const _EventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final isFestival = event.isFestival;
    final accentColor =
        isFestival ? AppColors.markerFestival : AppColors.primary;
    final bgColor = accentColor.withValues(alpha: 0.08);
    final borderColor = accentColor.withValues(alpha: 0.18);

    final now = DateTime.now();
    final dDay = event.startDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final dLabel = dDay > 0 ? 'D-$dDay' : (dDay == 0 ? 'D-Day' : 'D+${-dDay}');

    final start = event.startDate;
    final end = event.endDate;
    final dateRange = '${start.month}.${start.day} ~ ${end.month}.${end.day}';

    return GestureDetector(
      onTap: () => context.push('/calendar'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFestival ? Icons.festival : Icons.restaurant_menu,
                size: 36,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dLabel,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(dateRange,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
