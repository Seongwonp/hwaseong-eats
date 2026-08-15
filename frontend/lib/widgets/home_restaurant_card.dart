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

// 새로 오픈 카드 (MAP과 동일한 구조, NEW 뱃지 + 사진 행)
class NewRestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;

  const NewRestaurantCard({super.key, required this.restaurant});

  String get _distanceText {
    final km = restaurant.distanceKm;
    if (km == null) return '';
    return km < 1.0 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoriteProvider).contains(restaurant.id);

    return InkWell(
      onTap: () =>
          context.push('/restaurant/${restaurant.id}', extra: restaurant),
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 가게명 + NEW 뱃지 + 하트
            Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      ref.read(favoriteProvider.notifier).toggle(restaurant.id),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? AppColors.primary : const Color(0xFFCCCCCC),
                    size: 22,
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

            const SizedBox(height: 4),

            // 거리 + 별점
            Row(
              children: [
                Icon(Icons.location_on, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 2),
                Text(_distanceText.isNotEmpty ? _distanceText : '-',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(width: 10),
                const Icon(Icons.star_rounded,
                    size: 13, color: Color(0xFFFFBB33)),
                const SizedBox(width: 2),
                Text(
                  '${restaurant.rating?.toStringAsFixed(1) ?? '-'} (${restaurant.reviewCount})',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 사진 썸네일 (placeholder)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, i) => Container(
                  width: 90,
                  height: 90,
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: Color(0xFFDDDDDD), size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
