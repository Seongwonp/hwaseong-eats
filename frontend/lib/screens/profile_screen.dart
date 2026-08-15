import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 타이틀 ────────────────────────────────────
              Padding(
                padding:
                    EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 16),
                child: const Text(
                  '내 정보',
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // ── 프로필 카드 ────────────────────────────────
              _Card(
                child: auth.isLoggedIn
                    ? _LoggedInProfile(auth: auth, onEdit: _showNicknameEdit)
                    : _LoggedOutProfile(),
              ),

              const SizedBox(height: 12),

              // ── 로그인 상태 전용 섹션들 ────────────────────
              if (auth.isLoggedIn) ...[
                // 내 포인트
                _Card(
                  child: Padding(
                    padding: EdgeInsets.all(context.hPad),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '내 포인트',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 22, color: Color(0xFFFFBB33)),
                                const SizedBox(width: 6),
                                Text(
                                  '${_formatPoints(auth.points)} P',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSerifKR',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '1,000P부터 교환 가능',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => context.push('/reward'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: const Text('교환하기',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 인증
                const _SectionLabel(label: '인증'),
                _Card(
                  child: Padding(
                    padding: EdgeInsets.all(context.hPad),
                    child: Row(
                      children: [
                        // 방패 아이콘
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '화성 시민 인증',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.isVerified ? (auth.expiresAt ?? '인증 완료') : '인증이 필요해요',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => context.push('/verify'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          child: Text(
                            auth.isVerified ? '갱신하기' : '인증하기',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],

              // ── 설정 ──────────────────────────────────────
              const _SectionLabel(label: '설정'),
              _Card(
                child: Column(
                  children: [
                    // 로그인 상태에서만 보이는 항목
                    if (auth.isLoggedIn) ...[
                      _NavRow(
                        label: '내가 쓴 식사평',
                        onTap: () => context.push('/my-reviews'),
                      ),
                      _Divider(),
                      _NavRow(
                        label: '저장한 가게',
                        onTap: () => context.push('/saved-restaurants'),
                      ),
                      _Divider(),
                    ],
                    // 알림 토글 (항상)
                    _ToggleRow(
                      label: '알림',
                      value: _notificationEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationEnabled = v),
                    ),
                    _Divider(),
                    _NavRow(
                      label: '개인정보 처리방침',
                      onTap: () => context.push('/privacy-policy'),
                    ),
                    _Divider(),
                    _NavRow(
                      label: '위치정보 이용약관',
                      onTap: () => _showSnack('위치정보 이용약관'),
                    ),
                    _Divider(),
                    _NavRow(
                      label: '데이터 출처 및 라이선스',
                      onTap: () => _showSnack('데이터 출처 및 라이선스'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 회원 탈퇴 (로그인만) ──────────────────────
              if (auth.isLoggedIn) ...[
                _Card(
                  child: _NavRow(
                    label: '회원 탈퇴',
                    labelColor: AppColors.primary,
                    icon: Icons.info_outline,
                    iconColor: AppColors.primary,
                    onTap: () => _confirmWithdraw(),
                  ),
                ),
                const SizedBox(height: 12),
                // 로그아웃
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                    },
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPoints(int p) {
    if (p >= 1000) {
      final k = p ~/ 1000;
      final r = p % 1000;
      return r == 0 ? '$k,000' : '$k,${r.toString().padLeft(3, '0')}';
    }
    return '$p';
  }

  void _showSnack(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$label — 준비 중'), duration: const Duration(seconds: 1)),
    );
  }

  void _showNicknameEdit() {
    final ctrl = TextEditingController(text: ref.read(authProvider).nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('닉네임 변경',
            style: TextStyle(
                fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: '2~10자 입력',
            hintStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final trimmed = ctrl.text.trim();
              if (trimmed.length < 2) return;
              Navigator.pop(ctx);
              final err = await ref.read(authProvider.notifier).updateNickname(trimmed);
              if (err != null && mounted) _showSnack(err);
            },
            child: const Text('변경',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmWithdraw() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원 탈퇴',
            style: TextStyle(
                fontFamily: 'NotoSerifKR', fontWeight: FontWeight.w700)),
        content: const Text('탈퇴하면 작성한 식사평과 포인트가 모두 삭제됩니다.\n정말 탈퇴하시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(authProvider.notifier).deleteAccount();
              if (!ok && mounted) {
                _showSnack('탈퇴 처리 중 오류가 발생했어요. 다시 시도해 주세요.');
              }
            },
            child: const Text('탈퇴', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── 로그인 프로필 ─────────────────────────────────────────────────────

class _LoggedInProfile extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onEdit;
  const _LoggedInProfile({required this.auth, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final nickname = auth.nickname ?? '화성 주민';
    return Padding(
      padding: EdgeInsets.all(context.hPad),
      child: Row(
        children: [
          // 아바타
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDDD0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          // 닉네임
          Expanded(
            child: Text(
              nickname,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFFCCCCCC)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('닉네임 변경',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── 비로그인 프로필 ───────────────────────────────────────────────────

class _LoggedOutProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/login'),
      child: Padding(
        padding: EdgeInsets.all(context.hPad),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.person, color: Color(0xFFBBBBBB), size: 30),
            ),
            const SizedBox(width: 14),
            const Text(
              '로그인 해주세요.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 공통 위젯들 ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFF2F2F2),
        indent: 20,
        endIndent: 20);
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _NavRow({
    required this.label,
    required this.onTap,
    this.labelColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? color),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
