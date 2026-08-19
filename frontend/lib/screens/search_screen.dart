import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/paginated_restaurants_provider.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/pagination_footer.dart';
import '../widgets/section_title.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // _query: TextField에 표시되는 현재 입력값
  // _debouncedQuery: 실제 API 요청에 쓰는 값 (400ms 지연 후 동기화)
  String _query = '';
  String _debouncedQuery = '';

  static const _categoryKeywords = [
    '일반음식점',
    '커피전문점',
    '치킨전문점',
    '제과.제빵',
  ];
  static const _popularKeywords = ['화성페이', '삼계탕', '장어', '국밥', '갈비'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _debouncedQuery.isEmpty) return;
    if (_scrollController.position.extentAfter < 500) {
      ref
          .read(paginatedRestaurantsProvider(_debouncedQuery).notifier)
          .loadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final normalized = value.trim();
    if (normalized.isEmpty) {
      setState(() => _debouncedQuery = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = normalized);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _setQuery(String value) {
    _controller.text = value;
    _onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
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
            hintText: '음식점 이름, 업종, 리뷰 태그 검색',
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
      body: _query.trim().isEmpty ? _buildSuggestions() : _buildResults(),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('업종으로 찾기'),
          const SizedBox(height: 10),
          _ChipWrap(
            keywords: _categoryKeywords,
            color: AppColors.markerSeasonal,
            onTap: _setQuery,
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
    if (_query.trim() != _debouncedQuery) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final search = ref.watch(
      paginatedRestaurantsProvider(_debouncedQuery),
    );

    if (search.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (search.initialError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('검색 중 오류가 발생했어요', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () => ref
                  .read(paginatedRestaurantsProvider(_debouncedQuery).notifier)
                  .retryInitial(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (search.items.isEmpty) {
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

    final showFooter =
        search.hasMore || search.isLoadingMore || search.loadMoreError != null;
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: search.items.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, index) => index < search.items.length - 1
          ? const Divider(height: 1)
          : const SizedBox.shrink(),
      itemBuilder: (_, index) {
        if (index == search.items.length) {
          return PaginationFooter(
            isLoading: search.isLoadingMore,
            hasError: search.loadMoreError != null,
            onRetry: () => ref
                .read(paginatedRestaurantsProvider(_debouncedQuery).notifier)
                .retryLoadMore(),
          );
        }
        final r = search.items[index];
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          onTap: () {
            // 지도 화면으로 돌아가서 이 가게를 선택 상태로 만든다
            // (마커 탭과 동일하게 지도 확대 + 프리뷰 카드 표시).
            ref.read(selectedRestaurantProvider.notifier).state = r;
            context.pop();
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
