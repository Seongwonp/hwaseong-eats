import 'package:dio/dio.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Dio get dio => _dio;

  // 음식점 목록 조회
  Future<Response> getRestaurants({bool? isHwaseongPay, String? category}) {
    return _dio.get(ApiConstants.restaurants, queryParameters: {
      if (isHwaseongPay != null) 'is_hwaseong_pay': isHwaseongPay,
      if (category != null) 'category': category,
    });
  }

  // 음식점 상세 조회
  Future<Response> getRestaurant(int id) {
    return _dio.get('${ApiConstants.restaurants}/$id');
  }

  // 오늘 절기·축제 조회
  Future<Response> getTodayFestivals() {
    return _dio.get(ApiConstants.festivalsToday);
  }

  // 리뷰 작성
  Future<Response> postReview(Map<String, dynamic> data) {
    return _dio.post(ApiConstants.reviews, data: data);
  }

  // 포인트 조회
  Future<Response> getRewards() {
    return _dio.get(ApiConstants.rewards);
  }
}
