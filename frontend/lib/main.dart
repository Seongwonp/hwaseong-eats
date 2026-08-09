import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';

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
      theme: AppTheme.theme,
      home: const Scaffold(
        body: Center(child: Text('화성뭐먹지?')),
      ),
    );
  }
}
