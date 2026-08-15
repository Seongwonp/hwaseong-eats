import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../widgets/home_restaurant_card.dart';

final _keywordRestaurantsProvider =
    FutureProvider.family<List<Restaurant>, String>((ref, keyword) async {
  final response = await ApiService().getRestaurants(q: keyword, limit: 30);
  final data = response.data as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>? ?? const [];
  return items
      .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
      .toList();
});

class KeywordRecommendationsScreen extends ConsumerStatefulWidget {
  const KeywordRecommendationsScreen({super.key});

  @override
  ConsumerState<KeywordRecommendationsScreen> createState() =>
      _KeywordRecommendationsScreenState();
}

class _KeywordRecommendationsScreenState
    extends ConsumerState<KeywordRecommendationsScreen> {
  String _selected = '화성페이';

  static const _keywords = [
    ('화성페이', Icons.payments_outlined),
    ('국밥', Icons.ramen_dining),
    ('갈비', Icons.restaurant),
    ('삼계탕', Icons.soup_kitchen_outlined),
    ('장어', Icons.set_meal_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(_keywordRestaurantsProvider(_selected));

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
          '키워드로 찾기',
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
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(context.hPad, 10, context.hPad, 10),
              itemCount: _keywords.length,
              itemBuilder: (_, index) {
                final (label, icon) = _keywords[index];
                final selected = _selected == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    avatar: Icon(
                      icon,
                      size: 14,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                    label: Text(label),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFDDDDDD),
                    ),
                    onSelected: (_) => setState(() => _selected = label),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: restaurants.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => _KeywordLoadError(
                onRetry: () =>
                    ref.invalidate(_keywordRestaurantsProvider(_selected)),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text(
                        '$_selected 검색 결과가 없어요',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(top: 4, bottom: context.hp(4)),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                      itemBuilder: (_, index) => HomeRestaurantCard(
                        restaurant: items[index],
                        leadingKeywords: [_selected],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordLoadError extends StatelessWidget {
  const _KeywordLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 10),
          const Text('음식점을 불러오지 못했어요'),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
