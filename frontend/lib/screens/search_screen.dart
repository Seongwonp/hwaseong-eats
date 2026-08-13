import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/seasonal_event.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../widgets/section_title.dart';

// 검색어 기반 음식점 API 조회. 빈 문자열이면 즉시 빈 목록 반환.
final _searchProvider =
    FutureProvider.family<List<Restaurant>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final res = await ApiService().getRestaurants(q: query, limit: 30);
  final data = res.data as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>? ?? [];
  return items
      .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
      .toList();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  // _query: TextField에 표시되는 현재 입력값
  // _debouncedQuery: 실제 API 요청에 쓰는 값 (400ms 지연 후 동기화)
  String _query = '';
  String _debouncedQuery = '';

  static const _seasonalKeywords = ['삼계탕', '장어', '포도', '수산물', '떡국', '팥죽'];
  static const _tagKeywords = ['카공픽', '10대픽', '혼밥', '가성비'];
  static const _popularKeywords = ['화성페이', '한식', '국밥', '돼지갈비', '포도'];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() => _debouncedQuery = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _debouncedQuery = value);
    });
  }

  void _setQuery(String value) {
    _controller.text = value;
    _onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final todayEvent = getTodayEvent();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '음식점 이름, 메뉴, 태그 검색',
            hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary.withValues(alpha: 0.4)),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _query.isEmpty
          ? _buildSuggestions(todayEvent)
          : _buildResults(),
    );
  }

  Widget _buildSuggestions(SeasonalEvent? todayEvent) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todayEvent != null) ...[
            SectionTitle('${todayEvent.name} 추천'),
            const SizedBox(height: 10),
            _ChipWrap(
              keywords: _seasonalKeywords,
              color: AppColors.markerSeasonal,
              onTap: _setQuery,
            ),
            const SizedBox(height: 24),
          ],
          const SectionTitle('태그로 찾기'),
          const SizedBox(height: 10),
          _ChipWrap(
            keywords: _tagKeywords.map((k) => '#$k').toList(),
            color: AppColors.primary,
            onTap: (k) => _setQuery(k.replaceFirst('#', '')),
          ),
          const SizedBox(height: 24),
          const SectionTitle('자주 찾는 키워드'),
          const SizedBox(height: 10),
          _ChipWrap(
            keywords: _popularKeywords,
            color: Colors.grey.shade600,
            onTap: _setQuery,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // 입력 중(_query != _debouncedQuery)에는 로딩 표시
    if (_query != _debouncedQuery) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final searchAsync = ref.watch(_searchProvider(_debouncedQuery));

    return searchAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('검색 중 오류가 발생했어요',
                style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () =>
                  ref.invalidate(_searchProvider(_debouncedQuery)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('"$_query" 검색 결과가 없어요',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = results[i];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              title: Text(
                r.name,
                style: const TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              subtitle: Text(r.address,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: r.isKonapay
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.markerPay.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('화성페이',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.markerPay)),
                    )
                  : null,
              onTap: () =>
                  context.push('/restaurant/${r.id}', extra: r),
            );
          },
        );
      },
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> keywords;
  final Color color;
  final ValueChanged<String> onTap;

  const _ChipWrap(
      {required this.keywords, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keywords
          .map((k) => GestureDetector(
                onTap: () => onTap(k),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(k,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ))
          .toList(),
    );
  }
}
