import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../providers/paginated_restaurants_provider.dart';
import '../widgets/home_restaurant_card.dart';
import '../widgets/pagination_footer.dart';

class KeywordRecommendationsScreen extends ConsumerStatefulWidget {
  const KeywordRecommendationsScreen({super.key});

  @override
  ConsumerState<KeywordRecommendationsScreen> createState() =>
      _KeywordRecommendationsScreenState();
}

class _KeywordRecommendationsScreenState
    extends ConsumerState<KeywordRecommendationsScreen> {
  final _scrollController = ScrollController();
  String _selected = '화성페이';

  static const _keywords = [
    ('화성페이', Icons.payments_outlined),
    ('국밥', Icons.ramen_dining),
    ('갈비', Icons.restaurant),
    ('삼계탕', Icons.soup_kitchen_outlined),
    ('장어', Icons.set_meal_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500) {
      ref.read(paginatedRestaurantsProvider(_selected).notifier).loadMore();
    }
  }

  void _selectKeyword(String keyword) {
    if (_selected == keyword) return;
    setState(() => _selected = keyword);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(paginatedRestaurantsProvider(_selected));

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
                    onSelected: (_) => _selectKeyword(label),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: restaurants.isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : restaurants.initialError != null
                    ? _KeywordLoadError(
                        onRetry: () => ref
                            .read(paginatedRestaurantsProvider(_selected)
                                .notifier)
                            .retryInitial(),
                      )
                    : restaurants.items.isEmpty
                        ? Center(
                            child: Text(
                              '$_selected 검색 결과가 없어요',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding:
                                EdgeInsets.only(top: 4, bottom: context.hp(4)),
                            itemCount: restaurants.items.length +
                                ((restaurants.hasMore ||
                                        restaurants.isLoadingMore ||
                                        restaurants.loadMoreError != null)
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, index) =>
                                index < restaurants.items.length - 1
                                    ? const Divider(
                                        height: 1,
                                        color: Color(0xFFF0F0F0),
                                      )
                                    : const SizedBox.shrink(),
                            itemBuilder: (_, index) {
                              if (index == restaurants.items.length) {
                                return PaginationFooter(
                                  isLoading: restaurants.isLoadingMore,
                                  hasError: restaurants.loadMoreError != null,
                                  onRetry: () => ref
                                      .read(paginatedRestaurantsProvider(
                                              _selected)
                                          .notifier)
                                      .retryLoadMore(),
                                );
                              }
                              return HomeRestaurantCard(
                                restaurant: restaurants.items[index],
                                leadingKeywords: [_selected],
                              );
                            },
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
