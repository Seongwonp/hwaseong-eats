import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/seasonal_event.dart';
import '../providers/festival_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month);
  }

  void _prevMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  List<SeasonalEvent> _eventsForDay(int day, List<SeasonalEvent> events) {
    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    return events.where((e) => e.containsDate(date)).toList();
  }

  List<SeasonalEvent> _upcomingEvents(List<SeasonalEvent> events) {
    final today = DateTime(_today.year, _today.month, _today.day);
    return events
        .where((e) => !DateTime(e.endDate.year, e.endDate.month, e.endDate.day).isBefore(today))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  @override
  Widget build(BuildContext context) {
    final festivalsAsync = ref.watch(festivalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: festivalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildBody([]),
          data: (events) => _buildBody(events),
        ),
      ),
    );
  }

  Widget _buildBody(List<SeasonalEvent> events) {
    final upcoming = _upcomingEvents(events);

    return CustomScrollView(
      slivers: [
        // 헤더
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 8),
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
            margin: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
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

                _buildDayGrid(events),
              ],
            ),
          ),
        ),

        // 범례
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 4, context.hPad, 0),
            child: Row(
              children: [
                _LegendDot(AppColors.markerSeasonal, '절기·명절'),
                const SizedBox(width: 16),
                _LegendDot(AppColors.markerFestival, '축제'),
              ],
            ),
          ),
        ),

        // 다가오는 먹거리 일정
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 12),
            child: Text('다가오는 먹거리 일정', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          ),
        ),

        if (upcoming.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 16),
              child: Text('다가오는 일정이 없어요', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final event = upcoming[i];
                  final color = event.isFestival ? AppColors.markerFestival : AppColors.markerSeasonal;
                  final dateLabel = event.startDate.day == event.endDate.day
                      ? '${event.startDate.month}월 ${event.startDate.day}일'
                      : '${event.startDate.month}월 ${event.startDate.day}일 ~ ${event.endDate.month}월 ${event.endDate.day}일';

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
                                Text(event.dDayText, style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15, color: color)),
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
                                  '$dateLabel · ${event.isFestival ? "축제" : event.eventType}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                if (event.location != null) ...[
                                  const SizedBox(height: 2),
                                  Text(event.location!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  );
                },
                childCount: upcoming.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildDayGrid(List<SeasonalEvent> events) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
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
            final dayEvents = _eventsForDay(day, events);
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
                    if (dayEvents.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: dayEvents.take(2).map((e) => Container(
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
