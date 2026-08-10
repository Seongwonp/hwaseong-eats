import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  // 목 데이터 — 백엔드 연결 전
  static const int _mockPoints = 1500;
  static const List<Map<String, dynamic>> _mockHistory = [
    {'type': 'earn', 'text': '화성인증 식사평', 'point': 500, 'date': '2026.08.03'},
    {'type': 'earn', 'text': '화성인증 식사평', 'point': 500, 'date': '2026.08.01'},
    {'type': 'earn', 'text': '화성인증 식사평', 'point': 500, 'date': '2026.07.29'},
    {'type': 'use', 'text': '화성페이 전환', 'point': -1000, 'date': '2026.07.25'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '리워드',
          style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 포인트 카드
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF7A33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('볏섬 포인트', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('화성주민 인증', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_mockPoints',
                        style: const TextStyle(fontFamily: 'NotoSerifKR', color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('P', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('화성인증 식사평 1건당 +500P', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),

            // 화성페이 전환 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _mockPoints >= 1000 ? () => _showConvertDialog(context) : null,
                  icon: const Text('💳', style: TextStyle(fontSize: 16)),
                  label: const Text('화성페이로 전환하기', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1,000P = 1,000원 화성페이 (최소 1,000P)',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.5)),
            ),

            const SizedBox(height: 28),

            // 포인트 적립 방법
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('포인트 적립 방법', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  _EarnCard(
                    emoji: '🏅',
                    title: '화성인증 식사평',
                    desc: '주민인증 + 영수증 인증 후 식사평 작성',
                    point: '+500P',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 내역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('포인트 내역', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ..._mockHistory.map((h) => _HistoryRow(
                    text: h['text'],
                    point: h['point'],
                    date: h['date'],
                    isEarn: h['type'] == 'earn',
                  )),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('화성페이 전환', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1,000 P를 화성페이 1,000원으로\n전환할까요?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('전환된 화성페이는 화성시 가맹점에서\n사용할 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: API 전환 요청
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('1,000P → 화성페이 1,000원 전환 완료!')),
              );
            },
            child: const Text('전환하기', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EarnCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final String point;

  const _EarnCard({required this.emoji, required this.title, required this.desc, required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(point, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String text;
  final int point;
  final String date;
  final bool isEarn;

  const _HistoryRow({required this.text, required this.point, required this.date, required this.isEarn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : ''}$point P',
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isEarn ? AppColors.markerPay : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
