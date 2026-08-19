import 'package:flutter/material.dart';

class KakaoLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const KakaoLoginButton({super.key, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '카카오로 계속하기',
      enabled: !loading,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Opacity(
          opacity: loading ? 0.5 : 1.0,
          child: Image.asset(
            'assets/images/kakao_login_large_wide.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}
