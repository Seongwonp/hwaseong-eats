import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/restaurant.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;
  final bool showNewBadge;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.showNewBadge = false,
  });

  // 화성시 중심 기준 대략적 거리 계산
  String get _distanceText {
    if (restaurant.lat == null || restaurant.lng == null) return '';
    const cLat = 37.1996;
    const cLng = 126.8312;
    final dlat = (restaurant.lat! - cLat) * 111.0;
    final dlng = (restaurant.lng! - cLng) * 111.0 * 0.86;
    final km = sqrt(dlat * dlat + dlng * dlng);
    return km < 1.0 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 음식 이미지
            Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: AppColors.primary.withValues(alpha: 0.4),
                    size: 30,
                  ),
                ),
                if (showNewBadge)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 가게명 + 즐겨찾기
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 카테고리 + 태그
                  Wrap(
                    spacing: 4,
                    children: [
                      if (restaurant.category != null)
                        _SmallChip(restaurant.category!, color: Colors.grey.shade200, textColor: Colors.grey.shade600),
                      ...restaurant.tags.take(2).map((t) => _SmallChip('#$t', color: AppColors.primary.withValues(alpha: 0.08), textColor: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 거리 + 별점
                  Row(
                    children: [
                      if (_distanceText.isNotEmpty) ...[
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(_distanceText, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                      ],
                      if (restaurant.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF5A623)),
                        const SizedBox(width: 2),
                        Text(
                          '${restaurant.rating!.toStringAsFixed(1)} (${restaurant.reviewCount})',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 배지 행
                  Row(
                    children: [
                      if (restaurant.isKonapay)
                        _Badge('💳 화성페이 가능', AppColors.markerPay),
                      if (restaurant.isMobeom) ...[
                        if (restaurant.isKonapay) const SizedBox(width: 4),
                        _Badge('🏆 모범음식점', Colors.blue),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _SmallChip(this.label, {required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
