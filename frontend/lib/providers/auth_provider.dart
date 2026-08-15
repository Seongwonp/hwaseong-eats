import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? nickname;
  final int points;
  final bool isVerified;
  final String? expiresAt;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.nickname,
    this.points = 0,
    this.isVerified = false,
    this.expiresAt,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? nickname,
    int? points,
    bool? isVerified,
    String? expiresAt,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      nickname: nickname ?? this.nickname,
      points: points ?? this.points,
      isVerified: isVerified ?? this.isVerified,
      expiresAt: expiresAt ?? this.expiresAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _api = ApiService();

  // 앱 시작 시 저장된 토큰으로 자동 로그인 시도
  Future<void> tryAutoLogin() async {
    final hasToken = await _api.hasToken();
    if (!hasToken) return;

    try {
      final res = await _api.getMe();
      final user = res.data;
      state = state.copyWith(
        isLoggedIn: true,
        nickname: user['nickname'] as String?,
        points: (user['points'] as num?)?.toInt() ?? 0,
        isVerified: user['is_resident_verified'] as bool? ?? false,
        expiresAt: _formatExpiry(user['resident_expires_at'] as String?),
      );
    } catch (_) {
      // 토큰 만료 등 → 로그아웃 상태 유지
      await _api.clearToken();
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.signup(email: email, password: password, nickname: nickname);
      // 회원가입 후 바로 로그인
      return await login(email: email, password: password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.login(email: email, password: password);
      final token = res.data['access_token'] as String;
      await _api.saveToken(token);

      // 사용자 정보 조회
      final meRes = await _api.getMe();
      final user = meRes.data;
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        nickname: user['nickname'] as String?,
        points: (user['points'] as num?)?.toInt() ?? 0,
        isVerified: user['is_resident_verified'] as bool? ?? false,
        expiresAt: _formatExpiry(user['resident_expires_at'] as String?),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }

  Future<bool> deleteAccount() async {
    try {
      await _api.deleteMe();
      await _api.clearToken();
      state = const AuthState();
      return true;
    } catch (_) {
      return false;
    }
  }

  void refreshPoints(int newPoints) {
    state = state.copyWith(points: newPoints);
  }

  static String? _formatExpiry(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}까지 유효';
    } catch (_) {
      return null;
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 409) return '이미 사용중인 이메일이에요.';
      if (code == 401) return '이메일 또는 비밀번호가 틀렸어요.';
      if (code == 429) return '잠시 후 다시 시도해 주세요.';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return '인터넷 연결을 확인해 주세요.';
      }
    }
    return '오류가 발생했어요. 다시 시도해 주세요.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
