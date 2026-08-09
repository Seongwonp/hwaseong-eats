import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  // 엔드포인트
  static const restaurants = '/restaurants';
  static const reviews = '/reviews';
  static const rewards = '/rewards';
  static const festivals = '/festivals';
  static const festivalsToday = '/festivals/today';
  static const auth = '/auth';
}

class AppConstants {
  // 리워드
  static const reviewPoints = 500;
  static const pointsPerKrw = 1000; // 1000P = 화성페이 전환 기준

  // 지도
  static const festivalRadiusKm = 3.0;
  static const defaultZoomLevel = 14;

  // 화성시 중심 좌표
  static const hwaseongLat = 37.1996;
  static const hwaseongLng = 126.8312;
}
