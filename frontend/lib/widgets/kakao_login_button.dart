import 'package:flutter/material.dart';

class KakaoLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const KakaoLoginButton({super.key, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF191919),
          disabledBackgroundColor: const Color(0xFFFEE500).withValues(alpha: 0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              child: const Text('K',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF191919))),
            ),
            const SizedBox(width: 8),
            const Text('카카오로 계속하기',
                style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF191919))),
          ],
        ),
      ),
    );
  }
}
