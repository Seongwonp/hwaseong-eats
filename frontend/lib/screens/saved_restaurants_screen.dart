import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../providers/favorite_provider.dart';

class SavedRestaurantsScreen extends ConsumerWidget {
  const SavedRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteProvider);
    final all = mockRestaurants;
    final saved = all.where((r) => favoriteIds.contains(r.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '저장한 가게',
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
          // 총 개수 + 정렬
          Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 ${saved.length}개의 저장한 가게',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    const Text('최근 저장순', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // 리스트
          Expanded(
            child: saved.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border, size: 48, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 10),
                        Text('저장한 가게가 없어요', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('마음에 드는 가게를 하트로 저장해보세요', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(bottom: context.hp(4)),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) => _SavedCard(restaurant: saved[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  final Restaurant restaurant;
  const _SavedCard({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/restaurant/${restaurant.id}', extra: restaurant),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 14),
        child: Row(
          children: [
            // 이미지
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restaurant, color: AppColors.primary.withValues(alpha: 0.3), size: 28),
            ),

            const SizedBox(width: 14),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant.address,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Color(0xFFBBBBBB)),
                      const SizedBox(width: 2),
                      const Text('1.5km', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFBB33)),
                      const SizedBox(width: 2),
                      Text(
                        '${restaurant.rating?.toStringAsFixed(1) ?? '-'} (${restaurant.reviewCount})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 하트 (저장됨 = 항상 빨간색)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(favoriteProvider.notifier).toggle(restaurant.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: const Icon(Icons.favorite, color: AppColors.primary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
