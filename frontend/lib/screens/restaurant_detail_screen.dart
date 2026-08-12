import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../providers/favorite_provider.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  String? _selectedReviewKeyword;
  String _selectedPhotoFilter = '전체';

  static const _reviewKeywords = ['가성비', '카공족', '혼밥', '10대 픽'];
  static const _keywordCounts = {'가성비': 32, '카공족': 32};
  static const _photoFilters = ['전체', '음식', '매장', '메뉴판'];

  // 목업 리뷰 데이터 (API 미연결 시)
  static const _mockReviews = [
    (
      author: '홍길동',
      reviewCount: 14,
      rating: 4.6,
      content: '국물이 깔끔하고 순두부가 너무 맛있었습니다! 김치도 맛있어서 다음에 또 오고싶어요!!',
      date: '2026.05.06',
      keywords: ['가성비'],
      extraKeywordCount: 4,
      photoCount: 4,
    ),
    (
      author: '홍길동',
      reviewCount: 1,
      rating: 4.7,
      content: '조용하고 분위기 좋아요. 아이스 라떼를 먹었는데 고소하고 부드러워요. 컵도 예쁘고 자리도 편해서 더 좋았습니다...',
      date: '2026.04.15',
      keywords: ['카공족', '10대 픽'],
      extraKeywordCount: 0,
      photoCount: 2,
    ),
  ];

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 복사됨'), duration: const Duration(seconds: 1)),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final isFav = ref.watch(favoriteProvider).contains(restaurant.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),

              // 가게명 + 영업상태 + 평점
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF2ECC40), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            '영업 중 · 21:30 영업 종료 · 라스트오더 20:40',
                            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFBB33)),
                        const SizedBox(width: 3),
                        Text(
                          '평점 ${restaurant.rating} · 리뷰 ${restaurant.reviewCount}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 탭 바
              const TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelColor: AppColors.primary,
                unselectedLabelColor: Color(0xFF999999),
                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: '개요'),
                  Tab(text: '사진'),
                  Tab(text: '리뷰'),
                  Tab(text: '정보'),
                ],
              ),

              // 탭 내용
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOverviewTab(restaurant, isFav),
                    _buildPhotosTab(),
                    _buildReviewsTab(restaurant),
                    _buildInfoTab(restaurant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────── 개요 탭 ────────────────────

  Widget _buildOverviewTab(Restaurant restaurant, bool isFav) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전화 / 공유 / 저장 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 14),
            child: Row(
              children: [
                Expanded(child: _actionButton(Icons.phone_outlined, '전화', () {
                  final phone = restaurant.phone;
                  if (phone != null && phone.isNotEmpty) {
                    _copyToClipboard(phone, '전화번호');
                  } else {
                    _showSnackBar('전화번호가 없어요');
                  }
                })),
                const SizedBox(width: 10),
                Expanded(child: _actionButton(Icons.share_outlined, '공유', () {
                  _showSnackBar('공유 기능 준비 중');
                })),
                const SizedBox(width: 10),
                Expanded(child: _actionButton(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  '저장',
                  () => ref.read(favoriteProvider.notifier).toggle(restaurant.id),
                  isActive: isFav,
                )),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // 기본 정보
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 14),
            child: Column(
              children: [
                _infoRow('장소', restaurant.address, onTap: () => _copyToClipboard(restaurant.address, '주소')),
                const SizedBox(height: 12),
                _infoRow('영업시간', '11:00-21:30 / 라스트오더 20:40'),
                const SizedBox(height: 12),
                _infoRow(
                  '전화',
                  restaurant.phone ?? '031-0000-0000',
                  onTap: () => _copyToClipboard(restaurant.phone ?? '', '전화번호'),
                ),
                const SizedBox(height: 12),
                _infoRow('링크', 'https://instagram.com/aaa\nhttps://facebook.com/aaa'),
              ],
            ),
          ),

          const Divider(height: 8, thickness: 8, color: Color(0xFFF6F6F6)),

          // 사진 그리드 (3x3)
          Padding(
            padding: EdgeInsets.all(context.hPad),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFFDDDDDD), size: 28),
              ),
            ),
          ),

          const Divider(height: 8, thickness: 8, color: Color(0xFFF6F6F6)),

          // 방문자 리뷰 섹션
          Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 0),
            child: const Text(
              '방문자 리뷰',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),

          // 키워드 chips
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _reviewKeywords.map((k) => _keywordChip(k, count: _keywordCounts[k])).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 리뷰 카드 2개 미리보기
          ..._mockReviews.map((r) => Column(
            children: [
              _reviewCard(r),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
          )),

          // 리뷰 전체 보기
          Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 24),
            child: OutlinedButton(
              onPressed: () => DefaultTabController.of(context).animateTo(2),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('리뷰 전체 보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── 사진 탭 ────────────────────

  Widget _buildPhotosTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필터 칩 (전체/음식/매장/메뉴판)
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(context.hPad, 10, context.hPad, 10),
            itemCount: _photoFilters.length,
            itemBuilder: (_, i) {
              final label = _photoFilters[i];
              final selected = _selectedPhotoFilter == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPhotoFilter = label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color: selected ? AppColors.primary : const Color(0xFFDDDDDD),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 사진 그리드
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 24),
            child: Column(
              children: [
                // 대표 사진
                Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, color: Color(0xFFCCCCCC), size: 36),
                      SizedBox(height: 8),
                      Text('대표 사진 01', style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
                    ],
                  ),
                ),
                // 2열 그리드
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 8,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (_, i) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.restaurant, color: Color(0xFFDDDDDD), size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────── 리뷰 탭 ────────────────────

  Widget _buildReviewsTab(Restaurant restaurant) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 방문자 리뷰 평점 개요
          const Text('방문자 리뷰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                restaurant.rating.toString(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text('/ 5.0', style: TextStyle(fontSize: 16, color: Color(0xFFAAAAAA))),
              ),
            ],
          ),
          Text(
            '리뷰 ${restaurant.reviewCount}개 · 아래 수치와 후기는 목업 예시',
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          // 키워드 섹션
          const Text('키워드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _reviewKeywords.map((k) {
              final selected = _selectedReviewKeyword == k;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedReviewKeyword = selected ? null : k;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Text(
                    _keywordCounts[k] != null ? '$k  ${_keywordCounts[k]}' : k,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 4),

          // 리뷰 리스트
          ..._mockReviews.map((r) => Column(
            children: [
              _reviewCard(r),
              const Divider(color: Color(0xFFF0F0F0)),
            ],
          )),

          const SizedBox(height: 8),
          // 식사평 남기기 버튼
          ElevatedButton(
            onPressed: () => context.push('/review/${widget.restaurant.id}', extra: widget.restaurant),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('식사평 남기기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ──────────────────── 정보 탭 ────────────────────

  Widget _buildInfoTab(Restaurant restaurant) {
    final pad = EdgeInsets.symmetric(horizontal: context.hPad);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 가게 정보 섹션
          Padding(
            padding: pad.copyWith(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가게 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('확인 가능한 기본 정보는 실제 값으로 반영',
                    style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                const SizedBox(height: 14),
                _infoTableRow('주소', restaurant.address),
                _infoTableDivider(),
                _infoTableRow('전화', restaurant.phone ?? '-'),
                _infoTableDivider(),
                _infoTableRow('영업시간', '11:00-21:30'),
                _infoTableDivider(),
                _infoTableRow('라스트오더', '20:40'),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const _ThickDivider(),

          // ── 요일별 영업시간 섹션
          Padding(
            padding: pad.copyWith(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('요일별 영업시간', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('현재 확인 가능한 정보 기준',
                    style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                const SizedBox(height: 12),
                ..._buildWeeklyHours(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const _ThickDivider(),

          // ── 이용 안내 섹션
          Padding(
            padding: pad.copyWith(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이용 안내', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _infoTableRow('포장', '가능'),
                _infoTableDivider(),
                _infoTableRow('배달', '가능'),
                _infoTableDivider(),
                _infoTableRow('주차', '정보 확인 필요'),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const _ThickDivider(),

          // ── 위치 섹션
          Padding(
            padding: pad.copyWith(top: 20, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('위치', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFCCCCCC), size: 32),
                      const SizedBox(height: 8),
                      Text(restaurant.address,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _ThickDivider(),

          // ── 정보 수정 요청 섹션
          Padding(
            padding: pad.copyWith(top: 20, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('정보 수정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('가게 정보가 다르다면 사용자가 수정 요청을 보낼 수 있는 영역',
                    style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showSnackBar('정보 수정 요청이 접수되었습니다'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('정보 수정 요청',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── 공통 위젯 ────────────────────

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(color: isActive ? AppColors.primary : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isActive ? AppColors.primary : AppColors.textPrimary),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                decoration: onTap != null ? TextDecoration.underline : null,
                decorationColor: const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _infoTableDivider() => const Divider(height: 1, color: Color(0xFFF0F0F0));

  List<Widget> _buildWeeklyHours() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days.map((d) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(d, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          const SizedBox(width: 24),
          const Text('11:00-21:30', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const Spacer(),
          const Text('라스트오더 20:40', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
        ],
      ),
    )).toList();
  }

  Widget _keywordChip(String label, {int? count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Text(
        count != null ? '$label  $count' : label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _reviewCard(
    ({
      String author,
      int reviewCount,
      double rating,
      String content,
      String date,
      List<String> keywords,
      int extraKeywordCount,
      int photoCount,
    }) review,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 + 화성 시민 인증
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '리뷰 ${review.reviewCount}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  const Text('화성 시민 인증', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 별점
          Row(
            children: List.generate(5, (i) => Icon(
              i < review.rating.floor()
                  ? Icons.star_rounded
                  : (i < review.rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
              size: 16, color: const Color(0xFFFFBB33),
            )),
          ),

          const SizedBox(height: 8),

          // 리뷰 내용 (인용 스타일)
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFDDDDDD), width: 3)),
            ),
            child: Text(
              review.content,
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
            ),
          ),

          const SizedBox(height: 8),

          Text(review.date, style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),

          const SizedBox(height: 10),

          // 사진 썸네일
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: review.photoCount,
              itemBuilder: (_, i) => Container(
                width: 72, height: 72,
                margin: EdgeInsets.only(right: i < review.photoCount - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFFDDDDDD), size: 24),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 키워드 chips
          Wrap(
            spacing: 6,
            children: [
              ...review.keywords.map((k) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              )),
              if (review.extraKeywordCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('+${review.extraKeywordCount}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// 섹션 구분용 두꺼운 회색 구분선 (SingleChildScrollView padding 안에서 fullwidth 효과)
class _ThickDivider extends StatelessWidget {
  const _ThickDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: const Color(0xFFF6F6F6),
      margin: const EdgeInsets.symmetric(horizontal: -20),
    );
  }
}
