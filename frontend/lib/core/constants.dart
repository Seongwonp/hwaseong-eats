import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  // 엔드포인트
  static const restaurants = '/restaurants';
  static const reviews = '/reviews';
  static const festivals = '/festivals';

  // 인증
  static const signup = '/auth/signup';
  static const login = '/auth/login';
  static const me = '/auth/me';
  static const verifyResident = '/auth/verify';
  static const myPoints = '/auth/me/points';
}

class AppConstants {
  // 리워드
  static const reviewPoints = 500;
  static const minExchangePoints = 1000;

  // 지도
  static const defaultZoomLevel = 8;

  // 화성시 중심 좌표
  static const hwaseongLat = 37.1996;
  static const hwaseongLng = 126.8312;
}
