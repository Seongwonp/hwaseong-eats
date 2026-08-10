import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  AuthRepository.initialize(appKey: dotenv.env['KAKAO_MAP_KEY']!);
  runApp(const ProviderScope(child: HwaseongEatsApp()));
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
