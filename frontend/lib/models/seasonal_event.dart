class SeasonalEvent {
  final String name;
  final DateTime date;
  final String foodKeyword;
  final bool isFestival;
  final String? location; // 축제 장소

  const SeasonalEvent({
    required this.name,
    required this.date,
    required this.foodKeyword,
    this.isFestival = false,
    this.location,
  });

  bool get isNear {
    final diff = date.difference(DateTime.now()).inDays;
    return diff >= -3 && diff <= 3;
  }

  String get dDayText {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }
}

final List<SeasonalEvent> seasonalEvents = [
  SeasonalEvent(name: '초복', date: DateTime(2026, 7, 16), foodKeyword: '삼계탕·보양식'),
  SeasonalEvent(name: '중복', date: DateTime(2026, 7, 26), foodKeyword: '삼계탕·장어'),
  SeasonalEvent(name: '말복', date: DateTime(2026, 8, 14), foodKeyword: '삼계탕·장어'),
  SeasonalEvent(name: '추석', date: DateTime(2026, 10, 6), foodKeyword: '송편·전·나물'),
  SeasonalEvent(name: '동지', date: DateTime(2026, 12, 22), foodKeyword: '팥죽'),
  SeasonalEvent(name: '송산포도축제', date: DateTime(2026, 9, 5), foodKeyword: '포도·와인', isFestival: true, location: '송산면 일대'),
  SeasonalEvent(name: '도농어울림축제', date: DateTime(2026, 10, 10), foodKeyword: '지역특산물', isFestival: true, location: '화성시 일대'),
];

SeasonalEvent? getTodayEvent() {
  for (final event in seasonalEvents) {
    if (event.isNear) return event;
  }
  return null;
}
