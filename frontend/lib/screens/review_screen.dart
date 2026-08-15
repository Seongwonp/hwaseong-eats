import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const ReviewScreen({super.key, required this.restaurant});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int? _rating;
  final Set<String> _selectedKeywords = {};
  final _contentController = TextEditingController();
  String? _recommendation; // '추천해요' | '보통이에요'
  String? _revisit; // '있어요' | '잘 모르겠어요'
  bool _submitting = false;

  static const _keywords = ['가성비', '카공족', '혼밥', '10대 픽'];
  static const _keywordCounts = {'가성비': 32, '카공족': 32};

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final contentLength = _contentController.text.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '리뷰 작성',
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showSnack('임시저장되었습니다'),
            child: const Text(
              '임시저장',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 가게 정보 헤더 ──────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: context.fs(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (restaurant.category != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      restaurant.category!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888)),
                    ),
                  ],
                  if (restaurant.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      restaurant.address,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 방문 인증 안내
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Color(0xFF888888)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '영수증 인증 기능 준비 중 · 현재 리뷰는 일반 리뷰로 등록돼요',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 평점 섹션 ────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('평점'),
                  const SizedBox(height: 4),
                  const Text(
                    '전체 만족도',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = _rating != null && i < _rating!;
                      return GestureDetector(
                        onTap: () => setState(() {
                          // 같은 별 다시 탭하면 해제
                          _rating = (_rating == i + 1) ? null : i + 1;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: filled
                                ? const Color(0xFFFFBB33)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 어떤 점이 좋았나요? ────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('어떤 점이 좋았나요?'),
                  const SizedBox(height: 4),
                  const Text(
                    '중복 선택 가능',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _keywords.map((k) {
                      final selected = _selectedKeywords.contains(k);
                      final count = _keywordCounts[k];
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedKeywords.remove(k);
                          } else {
                            _selectedKeywords.add(k);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFFEEEEEE),
                            ),
                          ),
                          child: Text(
                            count != null ? '$k  $count' : k,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 리뷰 내용 ────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('리뷰 내용'),
                  const SizedBox(height: 4),
                  const Text(
                    '욕설, 허위 사실, 개인정보는 포함할 수 없습니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLength: 100,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          '리뷰를 입력하세요\n\n예:\n버거가 따뜻하게 나와서 좋았고 감자튀김도 바삭했어요.\n점심시간이었는데 생각보다 빠르게 받아서 만족했습니다.',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFFCCCCCC), height: 1.6),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$contentLength / 100',
                      style: TextStyle(
                        fontSize: 12,
                        color: contentLength > 80
                            ? AppColors.primary
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 추가 선택 ─────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('추가 선택'),
                  const SizedBox(height: 16),

                  // 추천 여부
                  const Text(
                    '이 가게를 추천하나요?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  _ChoiceRow(
                    options: const ['추천해요', '보통이에요'],
                    selected: _recommendation,
                    onSelect: (v) => setState(() => _recommendation = v),
                  ),

                  const SizedBox(height: 18),

                  // 재방문 의사
                  const Text(
                    '재방문 의사가 있나요?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  _ChoiceRow(
                    options: const ['있어요', '잘 모르겠어요'],
                    selected: _revisit,
                    onSelect: (v) => setState(() => _revisit = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 사진 첨부 ─────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sectionTitle('사진 첨부'),
                      const SizedBox(width: 8),
                      const Text(
                        '선택 사항',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showSnack('사진 첨부 기능 준비 중'),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 32, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 8),
                          Text(
                            '사진 첨부 영역',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFAAAAAA)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '예: 음식 사진, 매장 사진  ·  최대 10장',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFBBBBBB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 등록 전 확인 ──────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '등록 전 확인',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    '작성한 리뷰는 다른 사용자에게 공개됩니다.',
                    '방문 인증 여부는 함께 표시될 수 있습니다.',
                    '서비스 운영 정책에 따라 숨김 처리될 수 있습니다.',
                  ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('· ',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF999999))),
                            Expanded(
                              child: Text(t,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF999999))),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 하단 버튼 [취소] [리뷰 등록] ─────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('취소',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFDDDDDD),
                        minimumSize: const Size(0, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              '리뷰 등록',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      _showSnack('리뷰 내용을 입력해주세요');
      return;
    }

    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.push('/login');
      return;
    }

    setState(() => _submitting = true);
    try {
      final tags = [
        ..._selectedKeywords,
        if (_recommendation != null) '추천:$_recommendation',
        if (_revisit != null) '재방문:$_revisit',
      ];
      final res = await ApiService().postReview(
        restaurantId: widget.restaurant.id,
        rating: _rating,
        tags: tags,
        comment: _contentController.text.trim(),
      );
      final earned = (res.data['earned_points'] as num?)?.toInt() ?? 0;
      final total = (res.data['total_points'] as num?)?.toInt() ?? auth.points;
      ref.read(authProvider.notifier).refreshPoints(total);
      if (mounted) _showRewardDialog(earned);
    } catch (e) {
      if (mounted) {
        final msg = e is DioException && e.response?.statusCode == 409
            ? '이미 이 음식점에 식사평을 남겼어요.'
            : '등록에 실패했어요. 다시 시도해 주세요.';
        _showSnack(msg);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showRewardDialog(int earned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              '+$earned P',
              style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              earned > 0 ? '화성인증 식사평 등록 완료!' : '식사평 등록 완료!',
              style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              earned > 0
                  ? '1,000P부터 화성페이로 전환할 수 있어요'
                  : '영수증 인증 기능이 준비되면 인증 포인트를 받을 수 있어요',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/map');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 46),
              ),
              child: const Text('확인',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 섹션 카드 (흰 배경 + 패딩) ────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 20),
      child: child,
    );
  }
}

// ── 2-선택 버튼 행 (추천/재방문) ────────────────────────────────────

class _ChoiceRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ChoiceRow(
      {required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt;
        final isFirst = options.first == opt;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isFirst ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
