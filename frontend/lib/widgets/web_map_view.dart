import 'package:flutter/material.dart';
import '../models/restaurant.dart';

class KakaoWebMap extends StatelessWidget {
  final double lat;
  final double lng;
  final List<Restaurant> restaurants;
  final Function(String markerId) onMarkerTap;
  final Function(double lat, double lng, int level) onCameraIdle;

  const KakaoWebMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.restaurants,
    required this.onMarkerTap,
    required this.onCameraIdle,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('지도는 모바일 앱에서 이용해주세요'));
  }
}
