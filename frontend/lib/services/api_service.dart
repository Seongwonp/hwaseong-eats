import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

const _tokenKey = 'auth_token';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // 앱 시작 시 저장된 토큰 로드 + baseUrl 세팅
  Future<void> initialize() async {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) _setAuthHeader(token);
  }

  // 로그인/회원가입 후 토큰 저장
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _setAuthHeader(token);
  }

  // 로그아웃 시 토큰 제거
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  void _setAuthHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ── 인증 ──────────────────────────────────────────────────

  Future<Response> signup(
      {required String email,
      required String password,
      required String nickname}) {
    return _dio.post(ApiConstants.signup, data: {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
  }

  Future<Response> login({required String email, required String password}) {
    return _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getMe() {
    return _dio.get(ApiConstants.me);
  }

  Future<Response> verifyResident() {
    return _dio.post(ApiConstants.verifyResident);
  }

  Future<Response> deleteMe() {
    return _dio.delete(ApiConstants.me);
  }

  // ── 음식점 ────────────────────────────────────────────────

  Future<Response> getRestaurants({
    bool? isKonapay,
    bool? isMobeom,
    String? category,
    String? categoryGroup,
    String? q,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 100,
    int offset = 0,
  }) {
    return _dio.get(ApiConstants.restaurants, queryParameters: {
      if (isKonapay != null) 'is_konapay': isKonapay,
      if (isMobeom != null) 'is_mobeom': isMobeom,
      if (category != null) 'category': category,
      if (categoryGroup != null) 'category_group': categoryGroup,
      if (q != null) 'q': q,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radius_km': radiusKm,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> getRestaurant(int id) {
    return _dio.get('${ApiConstants.restaurants}/$id');
  }

  // ── 절기·축제 ──────────────────────────────────────────────

  Future<Response> getEvents({bool upcomingOnly = true}) {
    return _dio.get(ApiConstants.festivals, queryParameters: {
      if (upcomingOnly) 'upcoming_only': true,
    });
  }

  Future<Response> getTodayEvents() {
    return _dio.get('${ApiConstants.festivals}/today');
  }

  // ── 리뷰 ──────────────────────────────────────────────────

  Future<Response> getReviews({
    int? restaurantId,
    bool certifiedOnly = false,
    int limit = 20,
    int offset = 0,
  }) {
    return _dio.get(ApiConstants.reviews, queryParameters: {
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (certifiedOnly) 'certified_only': true,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> postReview({
    required int restaurantId,
    int? rating,
    List<String>? tags,
    String? comment,
  }) {
    return _dio.post(ApiConstants.reviews, data: {
      'restaurant_id': restaurantId,
      if (rating != null) 'rating': rating,
      if (tags != null) 'tags': tags,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<Response> getMyReviews() {
    return _dio.get('${ApiConstants.reviews}/me');
  }

  // ── 포인트 ────────────────────────────────────────────────

  Future<Response> getMyPoints({int limit = 50, int offset = 0}) {
    return _dio.get(ApiConstants.myPoints, queryParameters: {
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> exchangePoints(int points) {
    return _dio
        .post('${ApiConstants.myPoints}/exchange', data: {'points': points});
  }
}
