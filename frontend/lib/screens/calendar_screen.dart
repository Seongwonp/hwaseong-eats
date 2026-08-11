import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month);
  }

  void _prevMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  // 이 달에 해당하는 이벤트
  List<SeasonalEvent> get _monthEvents => seasonalEvents
      .where((e) => e.date.year == _focusedMonth.year && e.date.month == _focusedMonth.month)
      .toList();

  // 다가오는 이벤트 (오늘 이후)
  List<SeasonalEvent> get _upcomingEvents {
    final cutoff = DateTime(_today.year, _today.month, _today.day);
    return seasonalEvents
        .where((e) => !e.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '먹거리 달력',
                      style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '화성시 축제를 확인해보세요',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),

            // 달력
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    // 월 네비게이션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 22),
                          onPressed: _prevMonth,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                          style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 22),
                          onPressed: _nextMonth,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 요일 헤더
                    Row(
                      children: ['일', '월', '화', '수', '목', '금', '토'].map((d) {
                        final isSun = d == '일';
                        final isSat = d == '토';
                        return Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSun ? Colors.red.shade300 : isSat ? Colors.blue.shade300 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    // 날짜 그리드
                    _buildDayGrid(),
                  ],
                ),
              ),
            ),

            // 이벤트 범례
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    _LegendDot(AppColors.markerSeasonal, '절기'),
                    const SizedBox(width: 16),
                    _LegendDot(AppColors.markerFestival, '축제'),
                  ],
                ),
              ),
            ),

            // 다가오는 먹거리 일정
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('다가오는 먹거리 일정', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final event = _upcomingEvents[i];
                    final dday = event.date.difference(DateTime(_today.year, _today.month, _today.day)).inDays;
                    final color = event.isFestival ? AppColors.markerFestival : AppColors.markerSeasonal;
                    return GestureDetector(
                      onTap: () => context.push('/map'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text('D-$dday', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.name, style: const TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${event.date.month}월 ${event.date.day}일 · ${event.isFestival ? "축제" : "절기"}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _upcomingEvents.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0=일, 1=월 ... 6=토
    final totalCells = startWeekday + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - startWeekday + 1;
            if (day < 1 || day > lastDay.day) return const Expanded(child: SizedBox(height: 36));

            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final isToday = date.year == _today.year && date.month == _today.month && date.day == _today.day;
            final events = _monthEvents.where((e) => e.date.day == day).toList();
            final isSunday = col == 0;
            final isSaturday = col == 6;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday
                                ? Colors.white
                                : isSunday
                                    ? Colors.red.shade300
                                    : isSaturday
                                        ? Colors.blue.shade300
                                        : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // 이벤트 점
                    if (events.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.take(2).map((e) => Container(
                          width: 4, height: 4,
                          margin: const EdgeInsets.only(right: 1),
                          decoration: BoxDecoration(
                            color: e.isFestival ? AppColors.markerFestival : AppColors.markerSeasonal,
                            shape: BoxShape.circle,
                          ),
                        )).toList(),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
