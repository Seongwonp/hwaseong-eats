import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/seasonal_event.dart';

class EventCard extends StatelessWidget {
  final SeasonalEvent event;
  final bool isPast;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    this.isPast = false,
    required this.onTap,
  });

  Color get _accentColor =>
      event.isFestival ? AppColors.markerFestival : AppColors.markerSeasonal;

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
            border: Border.all(
              color:
                  event.isNear && !isPast ? _accentColor : Colors.grey.shade200,
              width: event.isNear && !isPast ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // 날짜 박스
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: isPast ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${event.date.month}월',
                      style: TextStyle(
                          fontSize: 10,
                          color: _accentColor,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${event.date.day}',
                      style: TextStyle(
                          fontFamily: 'NotoSerifKR',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _accentColor),
                    ),
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
                        Text(
                          event.name,
                          style: const TextStyle(
                              fontFamily: 'NotoSerifKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.isFestival ? '축제' : '절기',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(event.foodKeyword,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (event.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 2),
                          Text(event.location!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade400)),
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
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: event.isNear ? _accentColor : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
