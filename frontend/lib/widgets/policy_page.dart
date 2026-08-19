import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 개인정보 처리방침 · 위치정보 이용약관 · 데이터 출처 등 약관류 화면의 공통 레이아웃.
class PolicyPage extends StatelessWidget {
  final String title;
  final List<PolicySection> sections;
  final String? footnote;

  const PolicyPage({
    super.key,
    required this.title,
    required this.sections,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              Text(section.heading,
                  style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(section.body,
                  style: const TextStyle(
                      fontSize: 13, height: 1.7, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
            ],
            if (footnote != null) ...[
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 16),
              Text(footnote!,
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.6,
                      color: AppColors.textPrimary.withValues(alpha: 0.5))),
            ],
          ],
        ),
      ),
    );
  }
}

class PolicySection {
  final String heading;
  final String body;
  const PolicySection({required this.heading, required this.body});
}
