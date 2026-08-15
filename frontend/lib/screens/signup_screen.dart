import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtrl.text.contains('@') &&
      _pwCtrl.text.length >= 6 &&
      _nicknameCtrl.text.trim().length >= 2 &&
      _agreed;

  Future<void> _signup() async {
    final ok = await ref.read(authProvider.notifier).signup(
          email: _emailCtrl.text.trim(),
          password: _pwCtrl.text,
          nickname: _nicknameCtrl.text.trim(),
        );
    if (ok && mounted) context.go('/verify');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('회원가입',
            style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('볏섬에 오신 걸 환영해요',
                style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('닉네임을 설정하고 화성 먹거리 지도를 만들어요',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary.withValues(alpha: 0.5))),
            const SizedBox(height: 36),
            _label('이메일'),
            const SizedBox(height: 8),
            _field(
                controller: _emailCtrl,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _label('비밀번호'),
            const SizedBox(height: 8),
            _field(
              controller: _pwCtrl,
              hint: '6자 이상',
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 20),
            _label('닉네임'),
            const SizedBox(height: 8),
            _field(controller: _nicknameCtrl, hint: '2~10자 입력', maxLength: 10),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _agreed ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _agreed
                              ? AppColors.primary
                              : Colors.grey.shade300),
                    ),
                    child: _agreed
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text('서비스 이용약관 및 개인정보처리방침에 동의합니다',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              Text(auth.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_canSubmit && !auth.isLoading) ? _signup : null,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('다음 — 화성주민 인증',
                        style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: Text('나중에 하기 (지도만 볼게요)',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary.withValues(alpha: 0.4))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 13,
          fontWeight: FontWeight.w700));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }
}
