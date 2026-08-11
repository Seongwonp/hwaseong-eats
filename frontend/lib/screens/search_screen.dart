import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';
import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/section_title.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const _seasonalKeywords = ['삼계탕', '장어', '포도', '수산물', '떡국', '팥죽'];
  static const _tagKeywords = ['카공픽', '10대픽', '혼밥', '가성비'];
  static const _popularKeywords = ['화성페이', '한식', '국밥', '돼지갈비', '포도'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Restaurant> get _results {
    final all = ref.read(restaurantProvider);
    if (_query.isEmpty) return [];
    return all.where((r) =>
      r.name.contains(_query) ||
      (r.category?.contains(_query) ?? false) ||
      r.tags.any((t) => t.contains(_query))
    ).toList();
  }

  void _setQuery(String value) {
    _controller.text = value;
    setState(() => _query = value);
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
            hintStyle: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.4)),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _controller.clear(); setState(() => _query = ''); },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: _query.isEmpty ? _buildSuggestions(todayEvent) : _buildResults(),
    );
  }

  Widget _buildSuggestions(SeasonalEvent? todayEvent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('"$_query" 검색 결과가 없어요', style: const TextStyle(color: Colors.grey)),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          title: Text(r.name, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text(r.address, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: r.isKonapay
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.markerPay.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('화성페이', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.markerPay)),
                )
              : null,
          onTap: () => context.pop(),
        );
      },
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> keywords;
  final Color color;
  final ValueChanged<String> onTap;

  const _ChipWrap({required this.keywords, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keywords.map((k) => GestureDetector(
        onTap: () => onTap(k),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(k, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ),
      )).toList(),
    );
  }
}
