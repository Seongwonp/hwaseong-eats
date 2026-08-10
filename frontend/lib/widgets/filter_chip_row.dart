import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/restaurant_provider.dart';
import '../core/theme.dart';

class FilterChipRow extends ConsumerWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: '화성페이',
            icon: '💳',
            selected: filter.hwaseongPay,
            onTap: () => ref.read(filterProvider.notifier).update(
                  (s) => s.copyWith(hwaseongPay: !s.hwaseongPay),
                ),
          ),
          const SizedBox(width: 8),
          ...['카공픽', '10대픽', '혼밥', '가성비'].map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: '#$tag',
                  selected: filter.tag == tag,
                  onTap: () => ref.read(filterProvider.notifier).update(
                        (s) => s.copyWith(
                          tag: s.tag == tag ? null : tag,
                          clearTag: s.tag == tag,
                        ),
                      ),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
