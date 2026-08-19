import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../core/theme.dart';

class RestaurantPreviewCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTapDetail;
  final VoidCallback onClose;

  const RestaurantPreviewCard({
    super.key,
    required this.restaurant,
    required this.onTapDetail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapDetail,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.arrow_back, size: 20,
                        color: Color(0xFF888888)),
                  ),
                ),
                const Text(
                  '목록으로',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: Color(0xFFCCCCCC), size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (restaurant.isKonapay) ...[
                  const SizedBox(width: 8),
                  _Badge('💳 화성페이', AppColors.markerPay),
                ],
                if (restaurant.isMobeom) ...[
                  const SizedBox(width: 6),
                  _Badge('🏆 모범', Colors.blue),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.category != null
                  ? '${restaurant.category} · ${restaurant.address}'
                  : restaurant.address,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (restaurant.rating != null || restaurant.distanceKm != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (restaurant.rating != null) ...[
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFFBB33)),
                    const SizedBox(width: 2),
                    Text(
                      '${restaurant.rating!.toStringAsFixed(1)} (${restaurant.reviewCount})',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                  if (restaurant.rating != null &&
                      restaurant.distanceKm != null)
                    const SizedBox(width: 10),
                  if (restaurant.distanceKm != null) ...[
                    const Icon(Icons.location_on,
                        size: 13, color: Color(0xFFBBBBBB)),
                    const SizedBox(width: 2),
                    Text(
                      '${restaurant.distanceKm!.toStringAsFixed(1)}km',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
