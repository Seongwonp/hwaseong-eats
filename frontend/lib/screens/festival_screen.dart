import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/seasonal_event.dart';
import '../widgets/event_card.dart';
import '../widgets/section_title.dart';

class FestivalScreen extends StatelessWidget {
  const FestivalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = seasonalEvents
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 3))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = seasonalEvents
        .where((e) => e.date.isBefore(now.subtract(const Duration(days: 3))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('절기·축제 달력', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(),
            const SizedBox(height: 24),

            if (upcoming.isNotEmpty) ...[
              const SectionTitle('다가오는 일정'),
              const SizedBox(height: 12),
              ...upcoming.map((e) => EventCard(
                event: e,
                onTap: () => context.go('/map'),
              )),
            ],

            if (past.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionTitle('지난 일정'),
              const SizedBox(height: 12),
              ...past.map((e) => EventCard(event: e, isPast: true, onTap: () {})),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.markerSeasonal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Text('📅', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '날짜를 탭하면 해당 기간 지도가 열려요.\n축제 기간엔 주변 3km 음식점이 보라색으로 표시돼요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
