import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/responsive.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 4),
              child: const Text('알림', style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 16),
              child: Text('화성시 먹거리 소식을 확인해보세요', style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.5))),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                children: const [
                  _NotificationItem(
                    icon: Icons.store_outlined,
                    iconColor: AppColors.primary,
                    title: '우리 집 근처에 새로 오픈한 가게',
                    body: '봄담읍에 새로 오픈한 \'화성인증 맛집\'이에요.',
                    timeAgo: '방금 전',
                    isUnread: true,
                  ),
                  _NotificationItem(
                    icon: Icons.celebration_outlined,
                    iconColor: AppColors.markerFestival,
                    title: '화성 송산포도축제 D-29',
                    body: '9월 6일 ~ 7일 · 송산면',
                    timeAgo: '1시간 전',
                    isUnread: true,
                  ),
                  _NotificationItem(
                    icon: Icons.star_outline_rounded,
                    iconColor: Color(0xFFF5A623),
                    title: '포인트가 1,000P 넘었어요.',
                    body: '포인트를 교환하여 화성페이를 사용해보세요.',
                    timeAgo: '16시간 전',
                    isUnread: false,
                  ),
                  _NotificationItem(
                    icon: Icons.shield_outlined,
                    iconColor: Colors.green,
                    title: '화성 주민 인증 기간이 얼마 남지 않았어요.',
                    body: '인증을 갱신하고 화성인증 배지를 유지하세요.',
                    timeAgo: '어제',
                    isUnread: false,
                  ),
                  _NotificationItem(
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.grey,
                    title: '알림을 놓치고 싶지 않다면?',
                    body: '푸시 알림을 켜두면 더 빠르게 소식을 받을 수 있어요.',
                    timeAgo: '어제',
                    isUnread: false,
                    hasAction: true,
                    actionLabel: '설정하기',
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

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;
  final bool hasAction;
  final String? actionLabel;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isUnread = false,
    this.hasAction = false,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.12) : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'NotoSerifKR',
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    if (hasAction && actionLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(actionLabel!, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
