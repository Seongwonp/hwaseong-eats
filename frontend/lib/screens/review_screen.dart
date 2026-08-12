import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/section_title.dart';
import '../widgets/attribute_selector.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const ReviewScreen({super.key, required this.restaurantId, required this.restaurantName});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int? _rating;
  final Map<String, String?> _attributes = {
    '양': null,
    '맵기': null,
  };
  final _menuController = TextEditingController();
  final _commentController = TextEditingController();
  bool _receiptVerified = false;
  bool _submitting = false;

  @override
  void dispose() {
    _menuController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          widget.restaurantName,
          style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HwaseongCertBanner(),
            const SizedBox(height: 24),

            const SectionTitle('별점'),
            const SizedBox(height: 10),
            _StarRating(
              rating: _rating,
              onRate: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 20),

            const SectionTitle('양이 어땠나요?'),
            const SizedBox(height: 10),
            AttributeSelector(
              options: const ['적음', '보통', '많음'],
              selected: _attributes['양'],
              onSelect: (v) => setState(() => _attributes['양'] = v),
            ),
            const SizedBox(height: 20),

            const SectionTitle('맵기는요?'),
            const SizedBox(height: 10),
            AttributeSelector(
              options: const ['안매움', '보통', '매움'],
              selected: _attributes['맵기'],
              onSelect: (v) => setState(() => _attributes['맵기'] = v),
            ),
            const SizedBox(height: 20),

            const SectionTitle('여기 뭐가 유명해요?'),
            const SizedBox(height: 10),
            _textField(controller: _menuController, hint: '대표 메뉴 이름 입력'),
            const SizedBox(height: 20),

            const SectionTitle('한 줄 코멘트'),
            const SizedBox(height: 10),
            _textField(controller: _commentController, hint: '맛, 분위기, 특이사항 등 자유롭게 (악의적 비방 불가)', maxLines: 3, maxLength: 100),
            const SizedBox(height: 20),

            _ReceiptVerifyButton(
              verified: _receiptVerified,
              onTap: () => setState(() => _receiptVerified = !_receiptVerified),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : () => _submit(context),
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('식사평 등록', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({required TextEditingController controller, required String hint, int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.push('/login');
      return;
    }

    setState(() => _submitting = true);
    try {
      final attrTags = _attributes.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}:${e.value}')
          .toList();
      final menu = _menuController.text.trim();
      if (menu.isNotEmpty) attrTags.add('메뉴:$menu');

      final res = await ApiService().postReview(
        restaurantId: widget.restaurantId,
        rating: _rating,
        tags: attrTags,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        isReceiptVerified: _receiptVerified,
      );
      final earned = (res.data['earned_points'] as num?)?.toInt() ?? 0;
      final total = (res.data['total_points'] as num?)?.toInt() ?? auth.points;
      ref.read(authProvider.notifier).refreshPoints(total);
      if (mounted) _showRewardPopup(context, earned);
    } catch (_) {
      // API 실패 시 mock 팝업 (해커톤 fallback)
      if (mounted) _showRewardPopup(context, 500);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showRewardPopup(BuildContext context, [int earned = 500]) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('+$earned P', style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text('화성인증 식사평 등록 완료!', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('1,000P부터 화성페이로 전환할 수 있어요', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); context.go('/map'); },
            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int? rating;
  final ValueChanged<int> onRate;

  const _StarRating({required this.rating, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = rating != null && i < rating!;
        return GestureDetector(
          onTap: () => onRate(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: filled ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

class _HwaseongCertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Text('🏅', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('화성인증 식사평', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(height: 2),
                Text('주민인증 + 영수증 인증 완료 시 화성인증 배지가 붙어요', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptVerifyButton extends StatelessWidget {
  final bool verified;
  final VoidCallback onTap;

  const _ReceiptVerifyButton({required this.verified, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: verified ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: verified ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              verified ? Icons.check_circle : Icons.receipt_long_outlined,
              color: verified ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('영수증 인증하기', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
