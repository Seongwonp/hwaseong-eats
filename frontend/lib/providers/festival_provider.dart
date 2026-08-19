import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seasonal_event.dart';
import '../services/api_service.dart';

final festivalsProvider = FutureProvider<List<SeasonalEvent>>((ref) async {
  try {
    final res = await ApiService().getEvents(upcomingOnly: true);
    final items = res.data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => SeasonalEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    final today = DateTime.now();
    return seasonalEvents
        .where((e) => !DateTime(e.endDate.year, e.endDate.month, e.endDate.day)
            .isBefore(DateTime(today.year, today.month, today.day)))
        .toList();
  }
});

final todayEventProvider = FutureProvider<SeasonalEvent?>((ref) async {
  try {
    final res = await ApiService().getTodayEvents();
    final primary = res.data['primary'];
    if (primary == null) return null;
    return SeasonalEvent.fromJson(primary as Map<String, dynamic>);
  } catch (_) {
    return getTodayEvent();
  }
});
