import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/home_restaurant_card.dart';

class KeywordRecommendationsScreen extends ConsumerStatefulWidget {
  const KeywordRecommendationsScreen({super.key});

  @override
  ConsumerState<KeywordRecommendationsScreen> createState() => _KeywordRecommendationsScreenState();
}

class _KeywordRecommendationsScreenState extends ConsumerState<KeywordRecommendationsScreen> {
  String _selected = '오늘의 추천';

  static const _keywords = [
    ('오늘의 추천', Icons.star_rounded),
    ('가성비', Icons.attach_money),
    ('카공족', Icons.laptop_mac),
    ('혼밥', Icons.restaurant),
    ('10대 픽', Icons.people),
  ];

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(restaurantProvider);

    // 키워드 선택에 따른 필터 (tags 기반, 목업이라 전부 표시)
    final filtered = _selected == '오늘의 추천'
        ? all
        : all.where((r) => r.tags.any((t) => t.contains(_selected))).toList();

    // 키워드가 없으면 전체 표시
    final shown = filtered.isEmpty ? all : filtered;

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
          '키워드 추천',
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
          // 키워드 필터 칩 (가로 스크롤)
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(context.hPad, 10, context.hPad, 10),
              itemCount: _keywords.length,
              itemBuilder: (_, i) {
                final (label, icon) = _keywords[i];
                final selected = _selected == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : const Color(0xFFDDDDDD),
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6)]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textPrimary),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // 음식점 리스트
          Expanded(
            child: shown.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 40, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 8),
                        Text('해당 키워드의 가게가 없어요', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(top: 4, bottom: context.hp(4)),
                    itemCount: shown.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) => HomeRestaurantCard(
                      restaurant: shown[i],
                      leadingKeywords: [_selected],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
