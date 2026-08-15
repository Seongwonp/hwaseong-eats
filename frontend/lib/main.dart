import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  AuthRepository.initialize(
    appKey: dotenv.env['KAKAO_MAP_KEY']!,
    baseUrl: 'http://localhost',
  );
  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  assert(kakaoKey.isNotEmpty, '.env에 KAKAO_NATIVE_APP_KEY가 없습니다. .env.example을 참고하세요.');
  KakaoSdk.init(nativeAppKey: kakaoKey);

  // 저장된 JWT 토큰 복원
  await ApiService().initialize();

  final container = ProviderContainer();
  await container.read(favoriteProvider.notifier).initialize();
  await container.read(authProvider.notifier).tryAutoLogin();

  runApp(UncontrolledProviderScope(
      container: container, child: const HwaseongEatsApp()));
}

class HwaseongEatsApp extends StatelessWidget {
  const HwaseongEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '볏섬',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
