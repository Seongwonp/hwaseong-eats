import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: HwaseongEatsApp()));
}

class HwaseongEatsApp extends StatelessWidget {
  const HwaseongEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '화성뭐먹지?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4F00), // 화성 오렌지
          surface: const Color(0xFFFFFEFB),   // 웜 크림
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFEFB),
        fontFamily: 'NotoSerifKR',
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('화성뭐먹지?')),
      ),
    );
  }
}
