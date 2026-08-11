import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/restaurant_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(restaurantProvider);
    final newOnes = newRestaurants;
    final upcomingEvent = seasonalEvents
        .where((e) => e.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final nextEvent = upcomingEvent.isNotEmpty ? upcomingEvent.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안녕하세요,',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '화성에서 밥이나 먹을까?',
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 키워드 추천 칩
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('키워드 추천', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                        Text('더보기 >', style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _KeywordChip('⭐ 오늘의 추천', selected: true),
                        const SizedBox(width: 8),
                        _KeywordChip('🍱 가성비'),
                        const SizedBox(width: 8),
                        _KeywordChip('☕ 카공족'),
                        const SizedBox(width: 8),
                        _KeywordChip('🍜 혼밥'),
                        const SizedBox(width: 8),
                        _KeywordChip('🎮 10대픽'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 추천 음식점 리스트
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('추천 맛집', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    Text('더보기 >', style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => RestaurantCard(
                    restaurant: restaurants[i],
                    onTap: () => context.push('/review/${restaurants[i].id}', extra: restaurants[i].name),
                  ),
                  childCount: restaurants.take(3).length,
                ),
              ),
            ),

            // 우리집 근처 새로 오픈
            if (newOnes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('우리집 근처 새로 오픈', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      Text('더보기 >', style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => RestaurantCard(
                      restaurant: newOnes[i],
                      showNewBadge: true,
                      onTap: () => context.push('/review/${newOnes[i].id}', extra: newOnes[i].name),
                    ),
                    childCount: newOnes.take(2).length,
                  ),
                ),
              ),
            ],

            // 화성 먹거리 행사 배너
            if (nextEvent != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('화성 먹거리 행사', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          Text('전체 보기 >', style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _EventBanner(event: nextEvent),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _KeywordChip(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  final SeasonalEvent event;
  const _EventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final dday = event.date.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: event.isFestival ? AppColors.markerFestival.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.isFestival ? AppColors.markerFestival.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: event.isFestival ? AppColors.markerFestival : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('D-$dday', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'NotoSerifKR')),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: event.isFestival ? AppColors.markerFestival : AppColors.textPrimary,
                  ),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(event.location!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${event.date.month}월 ${event.date.day}일',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
