import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

typedef _ReviewItem = ({
  int id,
  Restaurant restaurant,
  int? rating,
  String? comment,
  List<String> tags,
  String date,
  bool isHwaseongCertified,
});

final _myReviewsProvider = FutureProvider<List<_ReviewItem>>((ref) async {
  final res = await ApiService().getMyReviews();
  final data = res.data as Map<String, dynamic>;
  final rawItems = (data['items'] as List).cast<Map<String, dynamic>>();

  final result = <_ReviewItem>[];
  for (final item in rawItems) {
    final restaurantId = item['restaurant_id'] as int;
    Restaurant restaurant;
    try {
      final rRes = await ApiService().getRestaurant(restaurantId);
      restaurant = Restaurant.fromJson(rRes.data as Map<String, dynamic>);
    } catch (_) {
      restaurant = Restaurant(
        id: restaurantId,
        name: '알 수 없는 가게',
        address: '',
        isKonapay: false,
        isMobeom: false,
        tags: [],
      );
    }

    final createdAt = DateTime.parse(item['created_at'] as String).toLocal();
    result.add((
      id: item['id'] as int,
      restaurant: restaurant,
      rating: item['rating'] as int?,
      comment: item['comment'] as String?,
      tags: List<String>.from(item['tags'] ?? []),
      date:
          '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}',
      isHwaseongCertified: item['is_hwaseong_certified'] as bool? ?? false,
    ));
  }
  return result;
});

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_myReviewsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '내가 쓴 식사평',
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 12),
              const Text('식사평을 불러오지 못했어요',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(_myReviewsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (reviews) => Column(
          children: [
            // ── 총 개수 + 정렬 ──────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 ${reviews.length}개의 식사평',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Row(
                    children: [
                      Text('최신순',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                      Icon(Icons.keyboard_arrow_down,
                          size: 16, color: Color(0xFF888888)),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

            // ── 리뷰 리스트 ────────────────────────────────
            Expanded(
              child: reviews.isEmpty
                  ? const _EmptyView()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
                      itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 리뷰 카드 ────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final _ReviewItem review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        '/restaurant/${review.restaurant.id}',
        extra: review.restaurant,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.hPad, 18, context.hPad, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 가게명 + 전체 보기 ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.restaurant.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.isHwaseongCertified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '화성인증',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.restaurant.address,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF999999)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push(
                    '/restaurant/${review.restaurant.id}',
                    extra: review.restaurant,
                  ),
                  child: const Text(
                    '전체 보기 >',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 별점 ────────────────────────────────────
            if (review.rating != null) ...[
              _StarRow(rating: review.rating!.toDouble()),
              const SizedBox(height: 10),
            ],

            // ── 리뷰 텍스트 (왼쪽 오렌지 보더) ─────────
            if (review.comment != null && review.comment!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                  color: Color(0xFFFFF9F6),
                ),
                child: Text(
                  review.comment!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 10),

            // ── 날짜 ────────────────────────────────────
            Text(
              review.date,
              style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),

            // ── 키워드 칩 ───────────────────────────────
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children:
                    review.tags.map((k) => _KeywordChip(label: k)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 별점 행 ──────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = rating >= i + 1;
          final half = !filled && rating >= i + 0.5;
          return Icon(
            half
                ? Icons.star_half_rounded
                : filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
            size: 18,
            color: const Color(0xFFFFBB33),
          );
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── 키워드 칩 ─────────────────────────────────────────────────────────

class _KeywordChip extends StatelessWidget {
  final String label;
  const _KeywordChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            '아직 작성한 식사평이 없어요',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          SizedBox(height: 4),
          Text(
            '방문한 가게의 식사평을 남겨보세요',
            style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }
}
