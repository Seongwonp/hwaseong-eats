import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nicknameController = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nicknameController.text.trim().length >= 2 && _agreed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('회원가입', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('볏섬에 오신 걸 환영해요', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('닉네임을 설정하고 화성 먹거리 지도를 만들어요', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5))),
            const SizedBox(height: 36),

            const Text('닉네임', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              maxLength: 10,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '2~10자 입력',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: _agreed ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _agreed ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  const Text('서비스 이용약관 및 개인정보처리방침에 동의합니다', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit ? () => context.go('/verify') : null,
                child: const Text('다음 — 화성주민 인증', style: TextStyle(fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.go('/map'),
                child: Text('나중에 하기 (지도만 볼게요)', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.4))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
