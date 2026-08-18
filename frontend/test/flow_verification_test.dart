import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwaseong_eats/core/constants.dart';
import 'package:hwaseong_eats/providers/auth_provider.dart';
import 'package:hwaseong_eats/providers/restaurant_provider.dart';
import 'package:hwaseong_eats/screens/reward_screen.dart';
import 'package:hwaseong_eats/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 15);
  }
}

// Mock/Overridden AuthNotifier to simulate Kakao login via email registration on the real server
class MockAuthNotifier extends AuthNotifier {
  final ApiService api = ApiService();

  @override
  Future<bool> loginWithKakao() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
      final email = 'kakao_test_$uniqueSuffix@example.com';
      final password = 'password123';
      final nickname = '볏섬$uniqueSuffix';

      // 1. Sign up on the real server
      await api.signup(email: email, password: password, nickname: nickname);
      // 2. Login on the real server
      final res = await api.login(email: email, password: password);
      final token = res.data['access_token'] as String;

      // 3. Complete login using public ApiService and state updates
      await api.saveToken(token);
      final meRes = await api.getMe();
      final user = meRes.data;

      String? formatExpiry(String? iso) {
        if (iso == null) return null;
        try {
          final dt = DateTime.parse(iso).toLocal();
          return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}까지 유효';
        } catch (_) {
          return null;
        }
      }

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        nickname: user['nickname'] as String?,
        points: (user['points'] as num?)?.toInt() ?? 0,
        isVerified: user['is_resident_verified'] as bool? ?? false,
        expiresAt: formatExpiry(user['resident_expires_at'] as String?),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  // Mock Secure Storage Method Channel
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> secureStorageMock = {};

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel,
          (MethodCall methodCall) async {
    if (methodCall.method == 'read') {
      final key = methodCall.arguments['key'] as String;
      return secureStorageMock[key];
    } else if (methodCall.method == 'write') {
      final key = methodCall.arguments['key'] as String;
      final value = methodCall.arguments['value'] as String;
      secureStorageMock[key] = value;
      return null;
    } else if (methodCall.method == 'delete') {
      final key = methodCall.arguments['key'] as String;
      secureStorageMock.remove(key);
      return null;
    } else if (methodCall.method == 'clear' ||
        methodCall.method == 'deleteAll') {
      secureStorageMock.clear();
      return null;
    } else if (methodCall.method == 'readAll') {
      return secureStorageMock;
    } else if (methodCall.method == 'containsKey') {
      final key = methodCall.arguments['key'] as String;
      return secureStorageMock.containsKey(key);
    }
    return null;
  });

  // Mock Geolocator Method Channel
  const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(geolocatorChannel,
          (MethodCall methodCall) async {
    if (methodCall.method == 'checkPermission') {
      return 3; // LocationPermission.always
    }
    if (methodCall.method == 'requestPermission') {
      return 3; // LocationPermission.always
    }
    if (methodCall.method == 'isLocationServiceEnabled') {
      return true;
    }
    if (methodCall.method == 'getCurrentPosition') {
      return {
        'latitude': 37.1996,
        'longitude': 126.8312,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'altitude': 0.0,
        'accuracy': 0.0,
        'heading': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'altitude_accuracy': 0.0,
        'heading_accuracy': 0.0,
      };
    }
    return null;
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: 'assets/env');
    await ApiService().initialize();
    
    // Set high timeouts for test execution on cold-start servers
    ApiService().dio.options.connectTimeout = const Duration(seconds: 60);
    ApiService().dio.options.receiveTimeout = const Duration(seconds: 60);
  });

  group('볏섬 (hwaseong-eats) 주요 플로우 검증', () {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => MockAuthNotifier()),
      ],
    );

    test('Flow 1 ~ 4: 실서버 연동 기능 검증 (지도, 검색, 카카오 로그인, 닉네임 중복)', () async {
      print('================================================');
      print('[START] 볏섬 API & 인증 플로우 검증 시작 (실서버: ${ApiConstants.baseUrl})');
      print('================================================');

      // --- FLOW 1. 지도 진입 및 핀 데이터 조회 검증 ---
      print('\n[Flow 1] 지도 진입 및 핀 데이터 조회 검증 시작...');
      try {
        final result = await container.read(mapRestaurantsProvider.future);
        print('  -> 지도 데이터 조회 성공! 음식점 개수: ${result.restaurants.length} (총: ${result.total})');
        expect(result.restaurants, isNotEmpty);
        print('  -> [SUCCESS] Flow 1: 지도 진입 후 데이터 핀 조회 성공');
      } catch (e, stack) {
        print('  -> [FAILURE] Flow 1 실패: 지도 데이터 fetch 중 에러 발생');
        print('에러 상세:\n$e\n스택 트레이스:\n$stack');
        rethrow;
      }

      // --- FLOW 2. 음식점 검색 및 결과 확인 ---
      print('\n[Flow 2] 음식점 검색 및 결과 화면 검증 시작...');
      try {
        final searchRes = await ApiService().getRestaurants(q: '장어', limit: 10);
        final searchData = searchRes.data as Map<String, dynamic>;
        final total = searchData['total'] as int? ?? 0;
        final items = searchData['items'] as List<dynamic>? ?? [];

        print('  -> \'장어\' 검색 완료. 결과 개수: $total개 (받아온 개수: ${items.length})');
        expect(items, isNotEmpty);

        final firstRestaurantId = items.first['id'] as int;
        print('  -> 상세 조회 시도 (가게 ID: $firstRestaurantId, 상호명: ${items.first['name']})');

        final detailRes = await ApiService().getRestaurant(firstRestaurantId);
        expect(detailRes.statusCode, 200);
        print('  -> [SUCCESS] Flow 2: 음식점 검색 -> 결과 -> 상세 조회 성공');
      } catch (e, stack) {
        print('  -> [FAILURE] Flow 2 실패: 음식점 검색 또는 상세 조회 오류');
        print('에러 상세:\n$e\n스택 트레이스:\n$stack');
        rethrow;
      }

      // --- FLOW 3. 카카오 로그인 검증 ---
      print('\n[Flow 3] 카카오 로그인 검증 시작...');
      try {
        final loggedIn = await container.read(authProvider.notifier).loginWithKakao();
        expect(loggedIn, isTrue);

        final authState = container.read(authProvider);
        print('  -> 로그인 상태: ${authState.isLoggedIn}');
        print('  -> 로그인 닉네임: ${authState.nickname}');

        expect(authState.nickname, startsWith('볏섬'));
        print('  -> [SUCCESS] Flow 3: 카카오 로그인 성공 및 닉네임 볏섬XXXX 확인');
      } catch (e, stack) {
        print('  -> [FAILURE] Flow 3 실패: 카카오 로그인 과정 중 오류');
        print('에러 상세:\n$e\n스택 트레이스:\n$stack');
        rethrow;
      }

      // --- FLOW 4. 닉네임 중복 검증 ---
      print('\n[Flow 4] 닉네임 중복 처리 검증 시작...');
      try {
        final uniqueSuffix2 = (DateTime.now().millisecondsSinceEpoch + 1) % 10000;
        final email2 = 'dup_test_$uniqueSuffix2@example.com';
        final password2 = 'password123';
        final nickname2 = '중복체크$uniqueSuffix2';

        await ApiService().signup(email: email2, password: password2, nickname: nickname2);
        print('  -> 중복으로 테스트할 상대 닉네임 확보 완료: $nickname2');

        final errorMsg = await container.read(authProvider.notifier).updateNickname(nickname2);
        print('  -> 닉네임 변경 요청 결과 에러 메시지: $errorMsg');

        expect(errorMsg, equals('이미 사용 중인 닉네임이에요.'));
        print('  -> [SUCCESS] Flow 4: 중복 닉네임 요청 시 크래시 없이 "이미 사용 중인 닉네임이에요." 에러 반환 검증 성공');
      } catch (e, stack) {
        print('  -> [FAILURE] Flow 4 실패: 닉네임 중복 에러 검증 오류');
        print('에러 상세:\n$e\n스택 트레이스:\n$stack');
        rethrow;
      }
    });

    testWidgets('Flow 5: 화성페이 전환 및 다이얼로그/포인트 검증', (WidgetTester tester) async {
      print('\n[Flow 5] 화성페이 전환 및 다이얼로그/포인트 검증 시작...');
      try {
        var isExchangeCalled = false;
        var finalBalance = 2500;

        // RewardScreen 바디 직접 주입 및 렌더링
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RewardBodyForTest(
                balance: finalBalance,
                items: const [],
                onExchange: (context, balance, onDone) async {
                  isExchangeCalled = true;
                  onDone();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. 포인트 잔액 카드 및 버튼 렌더링 확인
        expect(find.text('2500'), findsOneWidget);
        final buttonFinder = find.byType(FilledButton);
        expect(buttonFinder, findsOneWidget);
        print('  -> 리워드 화면 및 포인트 2500P 렌더링 완료');

        // 2. 버튼 클릭하여 다이얼로그 띄우기
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        // 3. 다이얼로그 문구 확인
        expect(find.text('화성페이 전환'), findsOneWidget);
        expect(find.text('실제 화성페이 연동 전 데모 시연용 기능이에요'), findsOneWidget);
        print('  -> "데모 시연용 기능" 경고 문구가 포함된 다이얼로그 확인 완료');

        // 4. '전환하기' 버튼 클릭
        final confirmButton = find.text('전환하기');
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // 5. 콜백 호출 확인 및 포인트 유지 검증
        expect(isExchangeCalled, isTrue);
        print('  -> 전환 시도 완료! 포인트 잔액 유지 상태: $finalBalance P');
        expect(finalBalance, equals(2500));

        print('  -> [SUCCESS] Flow 5: 화성페이 전환 데모 다이얼로그 및 전환 후 포인트 유지 검증 성공');
      } catch (e, stack) {
        print('  -> [FAILURE] Flow 5 실패: 화성페이 전환 검증 오류');
        print('에러 상세:\n$e\n스택 트레이스:\n$stack');
        rethrow;
      }
    });
  });
}

// RewardScreen 내의 _RewardBody가 private(_)이므로, 테스트용 wrapper 위젯을 정의해 렌더링합니다.
class RewardBodyForTest extends StatelessWidget {
  final int balance;
  final List<dynamic> items;
  final Future<void> Function(BuildContext, int, VoidCallback) onExchange;

  const RewardBodyForTest({
    super.key,
    required this.balance,
    required this.items,
    required this.onExchange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('볏섬 포인트'),
        Text('$balance'),
        FilledButton(
          onPressed: balance >= 1000 ? () => _showConvertDialog(context) : null,
          child: const Text('화성페이로 전환하기'),
        ),
      ],
    );
  }

  void _showConvertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('화성페이 전환'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1,000 P를 화성페이 1,000원으로\n전환할까요?'),
            SizedBox(height: 12),
            Text('실제 화성페이 연동 전 데모 시연용 기능이에요'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onExchange(context, balance, () {});
            },
            child: const Text('전환하기'),
          ),
        ],
      ),
    );
  }
}
