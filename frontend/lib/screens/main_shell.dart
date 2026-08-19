import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'map_screen.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 2});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _screens = [
    MapScreen(),
    CalendarScreen(),
    HomeScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: '지도',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: '캘린더',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _HomeNavItem(currentIndex: currentIndex, onTap: onTap),
              _NavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: '알림',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: '내정보',
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? AppColors.primary : Colors.grey.shade400),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color:
                        isActive ? AppColors.primary : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

// 중앙 홈 버튼 — 살짝 강조
class _HomeNavItem extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HomeNavItem({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.home_rounded,
                  size: 24,
                  color: isActive ? Colors.white : Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
