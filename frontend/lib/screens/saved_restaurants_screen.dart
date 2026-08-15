import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/restaurant.dart';
import '../providers/favorite_provider.dart';
import '../services/api_service.dart';

final _savedRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final ids = ref.watch(favoriteProvider).toList().reversed.toList();
  final staleIds = <int>[];

  final results = await Future.wait(ids.map((id) async {
    try {
      final response = await ApiService().getRestaurant(id);
      return Restaurant.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) staleIds.add(id);
      // 404 외 에러(네트워크 등)는 목록 유지, 재시도 가능
      return null;
    }
  }));

  // 서버에서 삭제된 음식점은 저장 목록에서 자동 정리
  for (final id in staleIds) {
    await ref.read(favoriteProvider.notifier).toggle(id);
  }

  return results.whereType<Restaurant>().toList();
});

class SavedRestaurantsScreen extends ConsumerWidget {
  const SavedRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteProvider).toList().reversed.toList();

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
      body: favoriteIds.isEmpty
          ? const _EmptySavedRestaurants()
          : ref.watch(_savedRestaurantsProvider).when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => _LoadError(
                  onRetry: () => ref.invalidate(_savedRestaurantsProvider),
                ),
                data: (restaurants) => _SavedRestaurantList(
                  restaurants: restaurants,
                ),
              ),
    );
  }
}

class _SavedRestaurantList extends StatelessWidget {
  const _SavedRestaurantList({required this.restaurants});

  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const _EmptySavedRestaurants(
        message: '저장한 가게 정보를 찾을 수 없어요',
        description: '삭제되었거나 현재 공개되지 않는 가게일 수 있어요',
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${restaurants.length}개의 저장한 가게',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '최근 저장순',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: context.hp(4)),
            itemCount: restaurants.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, index) =>
                _SavedCard(restaurant: restaurants[index]),
          ),
        ),
      ],
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () =>
          context.push('/restaurant/${restaurant.id}', extra: restaurant),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.restaurant,
                color: AppColors.primary.withValues(alpha: 0.3),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (restaurant.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFFFBB33),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${restaurant.rating!.toStringAsFixed(1)} '
                          '(${restaurant.reviewCount})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: '저장 해제',
              onPressed: () =>
                  ref.read(favoriteProvider.notifier).toggle(restaurant.id),
              icon: const Icon(
                Icons.favorite,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySavedRestaurants extends StatelessWidget {
  const _EmptySavedRestaurants({
    this.message = '저장한 가게가 없어요',
    this.description = '마음에 드는 가게를 저장해보세요',
  });

  final String message;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 48,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 10),
          const Text('저장한 가게를 불러오지 못했어요'),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
