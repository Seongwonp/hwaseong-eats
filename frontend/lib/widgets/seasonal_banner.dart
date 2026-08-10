import 'package:flutter/material.dart';
import '../models/seasonal_event.dart';
import '../core/theme.dart';

class SeasonalBanner extends StatelessWidget {
  final SeasonalEvent event;

  const SeasonalBanner({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.markerSeasonal,
      child: Row(
        children: [
          const Text('🍗', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${event.name} ${event.dDayText} · ${event.foodKeyword} 먹기 좋은 날',
              style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              event.dDayText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
