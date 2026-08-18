import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import '../providers/festival_provider.dart';
import '../models/seasonal_event.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final festivalsAsync = ref.watch(festivalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 4),
              child: const Text('알림',
                  style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 16),
              child: Text('화성시 먹거리 소식을 확인해보세요',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.5))),
            ),
            Expanded(
              child: festivalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildList(context, auth, []),
                data: (events) => _buildList(context, auth, events),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AuthState auth, List<SeasonalEvent> events) {
    // 1. 가장 가까운 축제 찾기
    SeasonalEvent? nearestFestival;
    for (final e in events) {
      if (e.isFestival && e.dDay >= 0) {
        if (nearestFestival == null || e.dDay < nearestFestival.dDay) {
          nearestFestival = e;
        }
      }
    }

    final festivalTitle = nearestFestival != null
        ? '화성 ${nearestFestival.name} ${nearestFestival.dDayText}'
        : '화성 송산포도축제 D-29';
    final festivalBody = nearestFestival != null
        ? '${nearestFestival.startDate.month}월 ${nearestFestival.startDate.day}일 ~ ${nearestFestival.endDate.month}월 ${nearestFestival.endDate.day}일 · ${nearestFestival.location ?? ""}'
        : '9월 6일 ~ 7일 · 송산면';

    // 2. 포인트 알림 분기
    final String pointTitle;
    final String pointBody;
    final bool pointUnread;
    final bool pointHasAction;
    final String? pointActionLabel;
    final VoidCallback? pointOnTap;

    if (auth.isLoggedIn) {
      if (auth.points >= 1000) {
        final formattedPoints = auth.points.toString().replaceAllMapped(
            RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},");
        pointTitle = '포인트가 ${formattedPoints}P 넘었어요.';
        pointBody = '포인트를 교환하여 화성페이를 사용해보세요.';
        pointUnread = true;
        pointHasAction = true;
        pointActionLabel = '교환하기';
        pointOnTap = () => context.push('/reward');
      } else {
        pointTitle = '현재 보유 포인트는 ${auth.points}P 입니다.';
        pointBody = '1,000P 이상 모으면 화성페이로 교환할 수 있어요!';
        pointUnread = false;
        pointHasAction = false;
        pointActionLabel = null;
        pointOnTap = () => context.push('/reward');
      }
    } else {
      pointTitle = '로그인하고 포인트를 적립해보세요!';
      pointBody = '화성인증 가맹점에서 식사평을 남기면 포인트가 적립됩니다.';
      pointUnread = false;
      pointHasAction = true;
      pointActionLabel = '로그인하기';
      pointOnTap = () => context.push('/login');
    }

    // 3. 주민인증 알림 분기
    final String verifyTitle;
    final String verifyBody;
    final bool verifyUnread;
    final bool verifyHasAction;
    final String? verifyActionLabel;
    final VoidCallback? verifyOnTap;

    if (auth.isLoggedIn) {
      if (auth.isVerified) {
        verifyTitle = '화성 주민 인증이 정상 유지 중입니다.';
        verifyBody = '${auth.expiresAt ?? "인증 완료"}. 혜택 배지를 유지하고 있어요.';
        verifyUnread = false;
        verifyHasAction = false;
        verifyActionLabel = null;
        verifyOnTap = () => context.push('/verify');
      } else {
        verifyTitle = '아직 화성 주민 인증을 하지 않으셨어요.';
        verifyBody = '주민 인증을 완료하면 식사평 포인트를 2배로 적립받을 수 있어요!';
        verifyUnread = true;
        verifyHasAction = true;
        verifyActionLabel = '인증하기';
        verifyOnTap = () => context.push('/verify');
      }
    } else {
      verifyTitle = '화성 시민이신가요?';
      verifyBody = '주민 인증 시 식사평 포인트 적립 2배 등 다양한 리워드를 누려보세요!';
      verifyUnread = false;
      verifyHasAction = true;
      verifyActionLabel = '알아보기';
      verifyOnTap = () => context.push('/signup');
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.hPad),
      children: [
        _NotificationItem(
          icon: Icons.store_outlined,
          iconColor: AppColors.primary,
          title: '우리 집 근처에 새로 오픈한 가게',
          body: '봄담읍에 새로 오픈한 \'화성인증 맛집\'이에요.',
          timeAgo: '방금 전',
          isUnread: true,
          onTap: () => context.push('/map'),
        ),
        _NotificationItem(
          icon: Icons.celebration_outlined,
          iconColor: AppColors.markerFestival,
          title: festivalTitle,
          body: festivalBody,
          timeAgo: '1시간 전',
          isUnread: true,
          onTap: () => context.push('/calendar'),
        ),
        _NotificationItem(
          icon: Icons.star_outline_rounded,
          iconColor: const Color(0xFFF5A623),
          title: pointTitle,
          body: pointBody,
          timeAgo: '16시간 전',
          isUnread: pointUnread,
          hasAction: pointHasAction,
          actionLabel: pointActionLabel,
          onTap: pointOnTap,
        ),
        _NotificationItem(
          icon: Icons.shield_outlined,
          iconColor: Colors.green,
          title: verifyTitle,
          body: verifyBody,
          timeAgo: '어제',
          isUnread: verifyUnread,
          hasAction: verifyHasAction,
          actionLabel: verifyActionLabel,
          onTap: verifyOnTap,
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('로컬 푸시 알림 설정은 모바일 OS 설정에서 관리할 수 있습니다.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
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
  final VoidCallback? onTap;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isUnread = false,
    this.hasAction = false,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.grey.shade100,
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
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(body,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      if (hasAction && actionLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(actionLabel!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
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
