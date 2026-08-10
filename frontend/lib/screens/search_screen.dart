import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';
import '../providers/restaurant_provider.dart';
import '../models/restaurant.dart';

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
      r.category.contains(_query) ||
      r.tags.any((t) => t.contains(_query))
    ).toList();
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
                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                    _controller.clear();
                    setState(() => _query = '');
                  })
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
            _SectionTitle('${todayEvent.name} 추천'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _seasonalKeywords.map((k) => _KeywordChip(
                label: k,
                color: AppColors.markerSeasonal,
                onTap: () {
                  _controller.text = k;
                  setState(() => _query = k);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          _SectionTitle('태그로 찾기'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagKeywords.map((k) => _KeywordChip(
              label: '#$k',
              color: AppColors.primary,
              onTap: () {
                _controller.text = k;
                setState(() => _query = k);
              },
            )).toList(),
          ),
          const SizedBox(height: 24),
          _SectionTitle('자주 찾는 키워드'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['화성페이', '한식', '국밥', '돼지갈비', '포도'].map((k) => _KeywordChip(
              label: k,
              color: Colors.grey.shade600,
              onTap: () {
                _controller.text = k;
                setState(() => _query = k);
              },
            )).toList(),
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
          trailing: r.isHwaseongPay
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
}

class _KeywordChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _KeywordChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}
