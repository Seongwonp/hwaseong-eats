import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';

class FestivalScreen extends StatelessWidget {
  const FestivalScreen({super.key});

  // seasonal_event.dart의 데이터 활용
  static List<SeasonalEvent> get _allEvents => [
    SeasonalEvent(name: '초복', date: DateTime(2026, 7, 16), foodKeyword: '삼계탕·보양식', isFestival: false),
    SeasonalEvent(name: '중복', date: DateTime(2026, 7, 26), foodKeyword: '삼계탕·장어', isFestival: false),
    SeasonalEvent(name: '말복', date: DateTime(2026, 8, 14), foodKeyword: '삼계탕·장어', isFestival: false),
    SeasonalEvent(name: '추석', date: DateTime(2026, 10, 6), foodKeyword: '송편·전·나물', isFestival: false),
    SeasonalEvent(name: '동지', date: DateTime(2026, 12, 22), foodKeyword: '팥죽', isFestival: false),
    SeasonalEvent(name: '송산포도축제', date: DateTime(2026, 9, 5), foodKeyword: '포도·와인', isFestival: true, location: '송산면 일대'),
    SeasonalEvent(name: '도농어울림축제', date: DateTime(2026, 10, 10), foodKeyword: '지역특산물', isFestival: true, location: '화성시 일대'),
  ]..sort((a, b) => a.date.compareTo(b.date));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = _allEvents.where((e) => e.date.isAfter(now.subtract(const Duration(days: 3)))).toList();
    final past = _allEvents.where((e) => e.date.isBefore(now.subtract(const Duration(days: 3)))).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('절기·축제 달력', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내
            Container(
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
            ),
            const SizedBox(height: 24),

            if (upcoming.isNotEmpty) ...[
              const Text('다가오는 일정', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...upcoming.map((e) => _EventCard(event: e, onTap: () => context.go('/map'))),
            ],

            if (past.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('지난 일정', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary.withValues(alpha: 0.4))),
              const SizedBox(height: 12),
              ...past.map((e) => _EventCard(event: e, isPast: true, onTap: () {})),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SeasonalEvent event;
  final bool isPast;
  final VoidCallback onTap;

  const _EventCard({required this.event, this.isPast = false, required this.onTap});

  Color get _accentColor => event.isFestival ? AppColors.markerFestival : AppColors.markerSeasonal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPast ? null : onTap,
      child: Opacity(
        opacity: isPast ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: event.isNear && !isPast ? _accentColor : Colors.grey.shade200, width: event.isNear && !isPast ? 1.5 : 1),
          ),
          child: Row(
            children: [
              // 날짜 박스
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: isPast ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${event.date.month}월', style: TextStyle(fontSize: 10, color: _accentColor, fontWeight: FontWeight.w700)),
                    Text('${event.date.day}', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 20, fontWeight: FontWeight.w700, color: _accentColor)),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // 이벤트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(event.name, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.isFestival ? '축제' : '절기',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(event.foodKeyword, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (event.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 2),
                          Text(event.location!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // D-day
              if (!isPast)
                Text(
                  event.dDayText,
                  style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 13, color: event.isNear ? _accentColor : Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
