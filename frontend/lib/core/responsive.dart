import 'package:flutter/material.dart';

extension Responsive on BuildContext {
  double get sw => MediaQuery.of(this).size.width;
  double get sh => MediaQuery.of(this).size.height;

  // 화면 너비 비율 (0~100)
  double wp(double percent) => sw * percent / 100;
  // 화면 높이 비율 (0~100)
  double hp(double percent) => sh * percent / 100;

  // 수평 패딩 기준값 (기준 390px 대비 비율)
  double get hPad => sw * 20 / 390;

  // 폰트 크기 스케일 (기준 390px)
  double fs(double size) => size * sw / 390;
}
