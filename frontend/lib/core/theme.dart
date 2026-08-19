import 'package:flutter/material.dart';

class AppColors {
  // 브랜드 컬러
  static const primary = Color(0xFFFF4F00); // 화성 오렌지
  static const background = Color(0xFFFFFEFB); // 웜 크림
  static const textPrimary = Color(0xFF201515); // 커피 잉크

  // 지도 마커
  static const markerDefault = Color(0xFF4A90D9); // 파랑 - 일반
  static const markerPay = Color(0xFF4CAF50); // 초록 - 화성페이
  static const markerSeasonal = Color(0xFFFF4F00); // 빨강 - 절기
  static const markerFestival = Color(0xFF9C27B0); // 보라 - 축제
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'NotoSerifKR',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
