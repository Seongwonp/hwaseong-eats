class SeasonalEvent {
  final String name;
  final DateTime date;
  final String foodKeyword; // 연관 음식 (삼계탕, 팥죽 등)
  final SeasonalType type;

  const SeasonalEvent({
    required this.name,
    required this.date,
    required this.foodKeyword,
    required this.type,
  });

  // 오늘 기준 ±3일 이내인지
  bool get isNear {
    final diff = date.difference(DateTime.now()).inDays;
    return diff >= -3 && diff <= 3;
  }

  // D-day 텍스트
  String get dDayText {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }
}

enum SeasonalType { seasonal, festival }

// 2026년 절기·축제 데이터
final List<SeasonalEvent> seasonalEvents = [
  SeasonalEvent(name: '초복', date: DateTime(2026, 7, 16), foodKeyword: '삼계탕', type: SeasonalType.seasonal),
  SeasonalEvent(name: '중복', date: DateTime(2026, 7, 26), foodKeyword: '삼계탕·장어', type: SeasonalType.seasonal),
  SeasonalEvent(name: '말복', date: DateTime(2026, 8, 14), foodKeyword: '삼계탕·장어', type: SeasonalType.seasonal),
  SeasonalEvent(name: '추석', date: DateTime(2026, 10, 6), foodKeyword: '송편·전', type: SeasonalType.seasonal),
  SeasonalEvent(name: '동지', date: DateTime(2026, 12, 22), foodKeyword: '팥죽', type: SeasonalType.seasonal),
  SeasonalEvent(name: '송산포도축제', date: DateTime(2026, 9, 5), foodKeyword: '포도·로컬맛집', type: SeasonalType.festival),
  SeasonalEvent(name: '도농어울림축제', date: DateTime(2026, 10, 10), foodKeyword: '로컬푸드', type: SeasonalType.festival),
];

SeasonalEvent? getTodayEvent() {
  for (final event in seasonalEvents) {
    if (event.isNear) return event;
  }
  return null;
}
