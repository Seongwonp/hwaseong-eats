import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../providers/favorite_provider.dart';

// 홈 화면 키워드 추천 섹션 카드
class HomeRestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;
  final List<String> leadingKeywords;

  const HomeRestaurantCard({
    super.key,
    required this.restaurant,
    this.leadingKeywords = const [],
  });

  String get _distanceText {
    final km = restaurant.distanceKm;
    if (km == null) return '';
    return km < 1.0 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)}km';
  }

  String get _keywordText {
    final all = [...leadingKeywords, ...restaurant.tags.take(2)];
    return all.join(' | ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoriteProvider).contains(restaurant.id);

    return GestureDetector(
      onTap: () =>
          context.push('/restaurant/${restaurant.id}', extra: restaurant),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 음식 이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.restaurant,
                  color: AppColors.primary.withValues(alpha: 0.3), size: 32),
            ),
            const SizedBox(width: 12),

            // 정보 컬럼
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 가게명 + 바로가기
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ref
                            .read(favoriteProvider.notifier)
                            .toggle(restaurant.id),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFav
                                ? AppColors.primary
                                : const Color(0xFFCCCCCC),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 키워드 (파이프 구분, 오렌지)
                  if (_keywordText.isNotEmpty)
                    Text(
                      _keywordText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 5),

                  // 거리 + 별점 + 바로가기
                  Row(
                    children: [
                      if (_distanceText.isNotEmpty) ...[
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(_distanceText,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                      ],
                      if (restaurant.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFBB33)),
                        const SizedBox(width: 2),
                        Text(
                          '${restaurant.rating!.toStringAsFixed(1)} (${restaurant.reviewCount})',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '바로가기 >',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
