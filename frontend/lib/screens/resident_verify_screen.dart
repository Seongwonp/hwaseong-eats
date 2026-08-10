import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class ResidentVerifyScreen extends StatefulWidget {
  const ResidentVerifyScreen({super.key});

  @override
  State<ResidentVerifyScreen> createState() => _ResidentVerifyScreenState();
}

class _ResidentVerifyScreenState extends State<ResidentVerifyScreen> {
  bool _verified = false;
  bool _loading = false;

  void _startVerify() async {
    setState(() => _loading = true);
    // TODO: 실제 주민등록 API 연결
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _verified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('화성주민 인증', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 배지 설명
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('화성인증 배지', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('화성 주민만 받을 수 있어요.\n인증된 리뷰어의 식사평은 배지가 붙어요.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('인증 단계', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            _StepRow(
              step: '1',
              title: '화성주민 인증',
              desc: '화성시 주민등록 기반 본인확인 (6개월 유효)',
              done: _verified,
            ),
            const SizedBox(height: 12),
            _StepRow(
              step: '2',
              title: '영수증 인증',
              desc: '식사평 작성 시 방문 영수증 첨부',
              done: false,
              pending: true,
            ),
            const SizedBox(height: 32),

            if (!_verified) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _startVerify,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('주민인증 시작', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.markerPay.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.markerPay.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 8),
                    Text('화성주민 인증 완료!', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.markerPay)),
                    SizedBox(height: 4),
                    Text('이제 화성인증 식사평을 남길 수 있어요', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/map'),
                  child: const Text('지도 보러 가기', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],

            const Spacer(),
            Center(
              child: Text('인증 정보는 화성주민 여부 확인 외 사용되지 않아요', style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.35))),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String title;
  final String desc;
  final bool done;
  final bool pending;

  const _StepRow({required this.step, required this.title, required this.desc, required this.done, this.pending = false});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.markerPay : (pending ? Colors.grey.shade300 : AppColors.primary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: pending ? Colors.grey : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
