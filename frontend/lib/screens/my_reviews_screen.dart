import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';

// 목 리뷰 데이터 (Dart 3 named records)
typedef _ReviewData = ({
  Restaurant restaurant,
  double rating,
  String text,
  String date,
  int views,
  int photoCount,
  List<String> keywords,
});

final _mockMyReviews = <_ReviewData>[
  (
    restaurant: mockRestaurants[0],
    rating: 4.6,
    text: '국물이 깔끔하고 순두부가 너무 맛있었습니다! 김치도 맛있어서 다음에 또 오고싶어요!!',
    date: '2026.05.06',
    views: 132,
    photoCount: 4,
    keywords: ['가성비', '+4'],
  ),
  (
    restaurant: mockRestaurants[1],
    rating: 4.7,
    text: '조용하고 분위기 좋아요. 아이스 라떼를 먹었는데 고소하고 부드러웠어요. 컵도 예쁘고 자리도 편해서 더 좋았습니다.',
    date: '2026.04.15',
    views: 25,
    photoCount: 2,
    keywords: ['카공족', '10대 픽'],
  ),
  (
    restaurant: mockRestaurants[0],
    rating: 4.6,
    text: '국물이 깔끔하고 순두부가 너무 맛있었습니다! 김치도 맛있어서 다음에 또 오고싶어요!!',
    date: '2026.03.20',
    views: 48,
    photoCount: 3,
    keywords: ['가성비'],
  ),
];

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = _mockMyReviews;

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
      body: Column(
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
                Row(
                  children: [
                    const Text('최신순', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF888888)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // ── 리뷰 리스트 ────────────────────────────────
          Expanded(
            child: reviews.isEmpty
                ? _EmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),
                    itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 리뷰 카드 ────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final _ReviewData review;
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
                      Text(
                        review.restaurant.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.restaurant.address,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
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
            _StarRow(rating: review.rating),

            const SizedBox(height: 10),

            // ── 리뷰 텍스트 (왼쪽 오렌지 보더) ─────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
                color: const Color(0xFFFFF9F6),
              ),
              child: Text(
                review.text,
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

            // ── 날짜 + 조회수 ────────────────────────────
            Row(
              children: [
                Text(
                  review.date,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
                const Spacer(),
                const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFFBBBBBB)),
                const SizedBox(width: 3),
                Text(
                  '${review.views}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),

            // ── 사진 썸네일 ──────────────────────────────
            if (review.photoCount > 0) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.primary.withValues(alpha: 0.25),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── 키워드 칩 ───────────────────────────────
            if (review.keywords.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: review.keywords.map((k) => _KeywordChip(label: k)).toList(),
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
        // 별 5개 (소수점 반영)
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
    final isExtra = label.startsWith('+');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isExtra ? const Color(0xFFF0F0F0) : const Color(0xFFFFF3EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isExtra ? const Color(0xFF999999) : AppColors.primary,
        ),
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
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
