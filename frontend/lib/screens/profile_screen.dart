import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // 목 데이터
  static const _nickname = '화성토박이';
  static const _isVerified = true;
  static const _points = 1500;
  static const _reviewCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('마이페이지', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              color: Colors.white,
              child: Column(
                children: [
                  // 아바타
                  Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('🍚', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(_nickname, style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 18)),
                      if (_isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🏅', style: TextStyle(fontSize: 11)),
                              SizedBox(width: 3),
                              Text('화성인증', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 포인트 코인 — PDF 10p: "프로필 바로 아래 코인으로 적립액 확인"
                  GestureDetector(
                    onTap: () => context.push('/reward'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFFF7A33)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          const Text('$_points P', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 활동 요약
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Row(
                children: [
                  _StatBox(label: '식사평', value: '$_reviewCount'),
                  _Divider(),
                  _StatBox(label: '적립 포인트', value: '$_points P'),
                  _Divider(),
                  _StatBox(label: '화성인증', value: _isVerified ? '✅' : '미완료'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 메뉴 리스트
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _MenuItem(icon: Icons.rate_review_outlined, label: '내 식사평', onTap: () {}),
                  _MenuItem(icon: Icons.card_giftcard_outlined, label: '리워드 내역', onTap: () => context.push('/reward')),
                  _MenuItem(icon: Icons.verified_user_outlined, label: '화성주민 인증', onTap: () => context.push('/verify')),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _MenuItem(icon: Icons.info_outline, label: '서비스 정보', onTap: () {}),
                  _MenuItem(icon: Icons.logout, label: '로그아웃', onTap: () => context.go('/map'), color: Colors.red.shade300),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.grey.shade200);
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c))),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
