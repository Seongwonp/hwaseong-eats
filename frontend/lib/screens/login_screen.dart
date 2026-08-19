import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/kakao_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtrl.text.contains('@') && _pwCtrl.text.length >= 6;

  Future<void> _login() async {
    final ok = await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _pwCtrl.text,
        );
    if (ok && mounted) context.go('/home');
  }

  Future<void> _loginWithKakao() async {
    final ok = await ref.read(authProvider.notifier).loginWithKakao();
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('로그인',
            style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다시 오셨군요!',
                style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('이메일로 로그인해 주세요',
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
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_canSubmit && !auth.isLoading) ? _login : null,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('로그인',
                        style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('또는', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            KakaoLoginButton(onTap: _loginWithKakao, loading: auth.isLoading),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('아직 계정이 없어요 → 회원가입',
                    style: TextStyle(fontSize: 13, color: AppColors.primary)),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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

