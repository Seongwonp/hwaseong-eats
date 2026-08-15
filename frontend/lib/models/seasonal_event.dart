class SeasonalEvent {
  final int id;
  final String name;
  final String eventType; // 절기 | 명절 | 축제
  final DateTime startDate;
  final DateTime endDate;
  final String foodKeyword;
  final String? location;
  final double? lat;
  final double? lng;
  final int dDay;
  final bool isActive;

  const SeasonalEvent({
    required this.id,
    required this.name,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    required this.foodKeyword,
    this.location,
    this.lat,
    this.lng,
    required this.dDay,
    required this.isActive,
  });

  // 기존 코드 호환
  DateTime get date => startDate;
  bool get isFestival => eventType == '축제';
  bool get isNear => isActive;

  String get dDayText {
    if (dDay == 0) return 'D-Day';
    if (dDay > 0) return 'D-$dDay';
    return 'D+${dDay.abs()}';
  }

  bool containsDate(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day)) &&
        !day.isAfter(DateTime(endDate.year, endDate.month, endDate.day));
  }

  factory SeasonalEvent.fromJson(Map<String, dynamic> json) => SeasonalEvent(
        id: json['id'],
        name: json['name'],
        eventType: json['event_type'],
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
        foodKeyword: json['food_keyword'] as String? ?? '',
        location: json['location'],
        lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
        lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
        dDay: json['d_day'],
        isActive: json['is_active'],
      );
}

// 백엔드 미연결 시 fallback
final List<SeasonalEvent> seasonalEvents = [
  SeasonalEvent(
      id: 1,
      name: '말복',
      eventType: '절기',
      startDate: DateTime(2026, 8, 14),
      endDate: DateTime(2026, 8, 14),
      foodKeyword: '삼계탕·장어',
      dDay: 2,
      isActive: true),
  SeasonalEvent(
      id: 2,
      name: '추석',
      eventType: '명절',
      startDate: DateTime(2026, 10, 6),
      endDate: DateTime(2026, 10, 8),
      foodKeyword: '송편·전·나물',
      dDay: 55,
      isActive: false),
  SeasonalEvent(
      id: 3,
      name: '동지',
      eventType: '절기',
      startDate: DateTime(2026, 12, 22),
      endDate: DateTime(2026, 12, 22),
      foodKeyword: '팥죽',
      dDay: 132,
      isActive: false),
  SeasonalEvent(
      id: 4,
      name: '송산포도축제',
      eventType: '축제',
      startDate: DateTime(2026, 9, 5),
      endDate: DateTime(2026, 9, 7),
      foodKeyword: '포도·와인',
      location: '송산면 일대',
      dDay: 24,
      isActive: false),
  SeasonalEvent(
      id: 5,
      name: '도농어울림축제',
      eventType: '축제',
      startDate: DateTime(2026, 10, 10),
      endDate: DateTime(2026, 10, 12),
      foodKeyword: '지역특산물',
      location: '화성시 일대',
      dDay: 59,
      isActive: false),
];

SeasonalEvent? getTodayEvent() {
  for (final event in seasonalEvents) {
    if (event.isActive) return event;
  }
  return null;
}
