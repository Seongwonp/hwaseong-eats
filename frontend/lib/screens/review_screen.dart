import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class ReviewScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const ReviewScreen({super.key, required this.restaurantId, required this.restaurantName});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final Map<String, String?> _attributes = {
    '양': null,      // 적음 | 보통 | 많음
    '맵기': null,    // 안매움 | 보통 | 매움
    '대표메뉴': null,
  };
  final _menuController = TextEditingController();
  final _commentController = TextEditingController();
  bool _receiptVerified = false;

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
            // 화성인증 안내
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
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
            ),
            const SizedBox(height: 24),

            // 양
            _SectionTitle('양이 어땠나요?'),
            const SizedBox(height: 10),
            _AttributeSelector(
              options: const ['적음', '보통', '많음'],
              selected: _attributes['양'],
              onSelect: (v) => setState(() => _attributes['양'] = v),
            ),
            const SizedBox(height: 20),

            // 맵기
            _SectionTitle('맵기는요?'),
            const SizedBox(height: 10),
            _AttributeSelector(
              options: const ['안매움', '보통', '매움'],
              selected: _attributes['맵기'],
              onSelect: (v) => setState(() => _attributes['맵기'] = v),
            ),
            const SizedBox(height: 20),

            // 대표메뉴
            _SectionTitle('여기 뭐가 유명해요?'),
            const SizedBox(height: 10),
            TextField(
              controller: _menuController,
              decoration: InputDecoration(
                hintText: '대표 메뉴 이름 입력',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 한줄 코멘트
            _SectionTitle('한 줄 코멘트'),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLength: 100,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '맛, 분위기, 특이사항 등 자유롭게 (악의적 비방 불가)',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 영수증 인증
            GestureDetector(
              onTap: () => setState(() => _receiptVerified = !_receiptVerified),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _receiptVerified ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _receiptVerified ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _receiptVerified ? Icons.check_circle : Icons.receipt_long_outlined,
                      color: _receiptVerified ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('영수증 인증하기', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    // TODO: 실제 영수증 이미지 업로드 연결
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 제출 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // TODO: API 연결
                  _showRewardPopup(context);
                },
                child: const Text('식사평 등록', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('+500 P', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text('화성인증 식사평 등록 완료!', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('1,000P부터 화성페이로 전환할 수 있어요', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/map');
            },
            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }
}

class _AttributeSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _AttributeSelector({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected == opt ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected == opt ? AppColors.primary : Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                opt,
                style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected == opt ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}
