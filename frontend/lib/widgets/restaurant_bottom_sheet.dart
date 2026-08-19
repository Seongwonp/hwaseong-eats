import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../core/theme.dart';
import '../providers/restaurant_detail_provider.dart';

class RestaurantBottomSheet extends ConsumerWidget {
  final Restaurant restaurant;

  const RestaurantBottomSheet({super.key, required this.restaurant});

  Color get markerColor {
    if (restaurant.isKonapay) return AppColors.markerPay;
    return AppColors.markerDefault;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurant.id));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 가게 헤더
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (restaurant.isKonapay) ...[
                          const SizedBox(width: 8),
                          const _Badge('💳 화성페이', AppColors.markerPay),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (restaurant.isMobeom)
                const _Badge('🏆 모범음식점', Colors.blue),
            ],
          ),

          // 태그
          if (restaurant.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: restaurant.tags
                  .map((tag) => _Badge('#$tag', AppColors.primary))
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 화성인증 리뷰 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '화성인증 식사평',
                style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              reviewsAsync.valueOrNull?.total != null &&
                      reviewsAsync.value!.total > 0
                  ? GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          '/restaurant/${restaurant.id}',
                          extra: restaurant,
                        );
                      },
                      child: Text(
                        '전체 보기 (${reviewsAsync.value!.total})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 8),

          reviewsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (_, __) => _emptyReviews(),
            data: (page) {
              if (page.items.isEmpty) return _emptyReviews();
              final previews = page.items.take(2).toList();
              return Column(
                children: previews
                    .map((r) => _ReviewTile(review: r))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          // 리뷰 작성 버튼
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/review/${restaurant.id}', extra: restaurant);
              },
              child: const Text('식사평 남기기',
                  style: TextStyle(
                      fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _emptyReviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16,
              color: AppColors.textPrimary.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            '아직 화성인증 식사평이 없어요',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  review.nickname,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (review.isHwaseongCertified) ...[
                  const SizedBox(width: 6),
                  const _Badge('화성인증', AppColors.primary),
                ],
                const Spacer(),
                if (review.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFFFBB33)),
                      const SizedBox(width: 2),
                      Text(
                        '${review.rating}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                review.comment!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
