import 'package:flutter/material.dart';
import '../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text('개인정보 처리방침', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text('개인정보 처리방침 내용이 들어갑니다.', style: TextStyle(fontSize: 14, height: 1.8)),
      ),
    );
  }
}
