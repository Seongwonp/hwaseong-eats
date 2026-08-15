import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// 포인트 내역 한 건
class _PointItem {
  final int delta;
  final String reason;
  final String date;
  const _PointItem(
      {required this.delta, required this.reason, required this.date});
}

// 포인트 내역 전체 (잔액 + 목록)
class _PointData {
  final int balance;
  final List<_PointItem> items;
  const _PointData({required this.balance, required this.items});
}

final _pointDataProvider = FutureProvider<_PointData>((ref) async {
  final res = await ApiService().getMyPoints();
  final balance = (res.data['balance'] as num).toInt();
  final rawItems = res.data['items'] as List<dynamic>? ?? [];
  final items = rawItems.map((e) {
    final map = e as Map<String, dynamic>;
    final dt = DateTime.parse(map['created_at'] as String).toLocal();
    final date =
        '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    return _PointItem(
      delta: (map['delta'] as num).toInt(),
      reason: map['reason'] as String,
      date: date,
    );
  }).toList();
  return _PointData(balance: balance, items: items);
});

class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointAsync = ref.watch(_pointDataProvider);
    final authPoints = ref.watch(authProvider).points;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '리워드',
          style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: pointAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 12),
              const Text('포인트 정보를 불러오지 못했어요',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(_pointDataProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (data) => _RewardBody(
          balance: data.balance,
          items: data.items,
          onExchange: (ctx, balance, onDone) =>
              _doExchange(ctx, ref, balance, onDone),
        ),
      ),
    );
  }

  Future<void> _doExchange(
    BuildContext context,
    WidgetRef ref,
    int balance,
    VoidCallback onDone,
  ) async {
    try {
      final res = await ApiService().exchangePoints(1000);
      final newBalance = (res.data['balance'] as num).toInt();
      ref.read(authProvider.notifier).refreshPoints(newBalance);
      ref.invalidate(_pointDataProvider);
      onDone();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('1,000P → 화성페이 1,000원 전환 완료!')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전환에 실패했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
    }
  }
}

class _RewardBody extends StatelessWidget {
  final int balance;
  final List<_PointItem> items;
  final Future<void> Function(BuildContext, int, VoidCallback) onExchange;

  const _RewardBody(
      {required this.balance, required this.items, required this.onExchange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 포인트 카드
          Container(
            margin: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 20),
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
                    const Text('볏섬 포인트',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('화성주민 인증',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$balance',
                      style: const TextStyle(
                          fontFamily: 'NotoSerifKR',
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('P',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('화성인증 식사평 1건당 +500P',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),

          // 화성페이 전환 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    balance >= 1000 ? () => _showConvertDialog(context) : null,
                icon: const Text('💳', style: TextStyle(fontSize: 16)),
                label: const Text('화성페이로 전환하기',
                    style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1,000P = 1,000원 화성페이 (최소 1,000P)',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary.withValues(alpha: 0.5)),
          ),

          const SizedBox(height: 28),

          // 포인트 적립 방법
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('포인트 적립 방법',
                    style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                SizedBox(height: 12),
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

          // 포인트 내역
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('포인트 내역',
                    style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Text('아직 내역이 없어요.',
                      style: TextStyle(fontSize: 13, color: Colors.grey))
                else
                  ...items.map((h) => _HistoryRow(
                        text: h.reason,
                        point: h.delta,
                        date: h.date,
                        isEarn: h.delta > 0,
                      )),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('화성페이 전환',
            style: TextStyle(
                fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1,000 P를 화성페이 1,000원으로\n전환할까요?',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('전환된 화성페이는 화성시 가맹점에서\n사용할 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              onExchange(context, balance, () {});
            },
            child: const Text('전환하기',
                style: TextStyle(
                    fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
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

  const _EarnCard(
      {required this.emoji,
      required this.title,
      required this.desc,
      required this.point});

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
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(point,
              style: const TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primary)),
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

  const _HistoryRow(
      {required this.text,
      required this.point,
      required this.date,
      required this.isEarn});

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
                Text(text,
                    style: const TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(date,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
