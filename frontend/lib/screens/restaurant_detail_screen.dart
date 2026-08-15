import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../providers/favorite_provider.dart';
import '../providers/restaurant_detail_provider.dart';

class InvalidRestaurantScreen extends StatelessWidget {
  const InvalidRestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('잘못된 음식점 주소예요.')),
      );
}

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final int restaurantId;
  final Restaurant? initialRestaurant;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    this.initialRestaurant,
  });

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  String? _selectedTag;

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _snack('$label 복사됨');
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(restaurantDetailProvider(widget.restaurantId));
    return detail.when(
      loading: () => widget.initialRestaurant == null
          ? _loadingScaffold()
          : _content(widget.initialRestaurant!),
      error: (_, __) => _errorScaffold(),
      data: _content,
    );
  }

  Widget _loadingScaffold() => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );

  Widget _errorScaffold() => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 44, color: Color(0xFFBBBBBB)),
              const SizedBox(height: 12),
              const Text('음식점 정보를 불러오지 못했어요.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(
                  restaurantDetailProvider(widget.restaurantId),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );

  Widget _content(Restaurant restaurant) {
    final reviews = ref.watch(restaurantReviewsProvider(restaurant.id));
    final isFavorite = ref.watch(favoriteProvider).contains(restaurant.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: context.fs(22),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      restaurant.rating == null
                          ? '아직 등록된 평점이 없어요'
                          : '평점 ${restaurant.rating!.toStringAsFixed(1)} · 리뷰 ${restaurant.reviewCount}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Color(0xFF999999),
                tabs: [
                  Tab(text: '개요'),
                  Tab(text: '사진'),
                  Tab(text: '리뷰'),
                  Tab(text: '정보'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _overview(restaurant, reviews, isFavorite),
                    _photosEmpty(),
                    _reviewsTab(restaurant, reviews),
                    _infoTab(restaurant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overview(
    Restaurant restaurant,
    AsyncValue<ReviewPage> reviews,
    bool isFavorite,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: _action(Icons.phone_outlined, '전화', () {
                final phone = restaurant.phone;
                phone == null || phone.isEmpty
                    ? _snack('전화번호가 없어요')
                    : _copy(phone, '전화번호');
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: _action(
                    Icons.share_outlined, '공유', () => _snack('공유 기능 준비 중'))),
            const SizedBox(width: 10),
            Expanded(
              child: _action(
                isFavorite ? Icons.bookmark : Icons.bookmark_border,
                '저장',
                () => ref.read(favoriteProvider.notifier).toggle(restaurant.id),
                active: isFavorite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _infoRow(
            '주소', restaurant.address, () => _copy(restaurant.address, '주소')),
        if (restaurant.phone?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _infoRow(
              '전화', restaurant.phone!, () => _copy(restaurant.phone!, '전화번호')),
        ],
        const Divider(height: 36),
        const Text('방문자 리뷰',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        reviews.when(
          loading: () => const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )),
          error: (_, __) => _reviewsError(restaurant.id),
          data: (page) => page.items.isEmpty
              ? _emptyReviews()
              : Column(
                  children: [
                    ...page.items.take(2).map(_reviewCard),
                    OutlinedButton(
                      onPressed: () =>
                          DefaultTabController.of(context).animateTo(2),
                      child: Text('리뷰 전체 보기 (${page.total})'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _photosEmpty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text('등록된 사진이 없어요.'),
          ],
        ),
      );

  Widget _reviewsTab(Restaurant restaurant, AsyncValue<ReviewPage> reviews) {
    return reviews.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _reviewsError(restaurant.id),
      data: (page) {
        final counts = <String, int>{};
        for (final review in page.items) {
          for (final tag in review.tags) {
            counts[tag] = (counts[tag] ?? 0) + 1;
          }
        }
        final visible = _selectedTag == null
            ? page.items
            : page.items
                .where((review) => review.tags.contains(_selectedTag))
                .toList();

        return ListView(
          padding: EdgeInsets.fromLTRB(context.hPad, 18, context.hPad, 32),
          children: [
            Text('방문자 리뷰 ${page.total}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (counts.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: counts.entries.map((entry) {
                  final selected = _selectedTag == entry.key;
                  return FilterChip(
                    selected: selected,
                    label: Text('${entry.key} ${entry.value}'),
                    onSelected: (_) => setState(
                      () => _selectedTag = selected ? null : entry.key,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (visible.isEmpty)
              _emptyReviews()
            else
              ...visible.map(_reviewCard),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await context.push(
                  '/review/${restaurant.id}',
                  extra: restaurant,
                );
                if (!mounted) return;
                ref.invalidate(restaurantDetailProvider(restaurant.id));
                ref.invalidate(restaurantReviewsProvider(restaurant.id));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('식사평 남기기'),
            ),
          ],
        );
      },
    );
  }

  Widget _reviewsError(int restaurantId) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('리뷰를 불러오지 못했어요.'),
            TextButton(
              onPressed: () =>
                  ref.invalidate(restaurantReviewsProvider(restaurantId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );

  Widget _emptyReviews() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 40, color: Color(0xFFCCCCCC)),
              SizedBox(height: 8),
              Text('아직 등록된 리뷰가 없어요.'),
            ],
          ),
        ),
      );

  Widget _reviewCard(Review review) {
    final date = review.createdAt
        .toLocal()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '.');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(review.nickname,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              if (review.isHwaseongCertified)
                const Text('화성인증',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
          if (review.rating != null) ...[
            const SizedBox(height: 6),
            Row(
                children: List.generate(
                    5,
                    (index) => Icon(
                          index < review.rating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 17,
                          color: const Color(0xFFFFBB33),
                        ))),
          ],
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: const TextStyle(height: 1.45)),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children:
                  review.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
          const SizedBox(height: 6),
          Text(date,
              style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _infoTab(Restaurant restaurant) => ListView(
        padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 32),
        children: [
          const Text('가게 정보',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _infoRow('주소', restaurant.address, null),
          if (restaurant.phone?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _infoRow('전화', restaurant.phone!, null),
          ],
          const Divider(height: 36),
          const Text('영업시간',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text('영업시간 정보가 없어요.',
              style: TextStyle(color: Color(0xFF999999))),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _snack('영업시간 제보 기능 준비 중'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('영업시간 입력하기'),
          ),
          const Divider(height: 36),
          const Text('위치',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(restaurant.address, textAlign: TextAlign.center),
          ),
        ],
      );

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {bool active = false}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? AppColors.primary : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 3),
          Text(label)
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 52,
                child: Text(label,
                    style: const TextStyle(color: Color(0xFF999999)))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
