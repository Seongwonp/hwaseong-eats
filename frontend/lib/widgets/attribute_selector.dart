import 'package:flutter/material.dart';
import '../core/theme.dart';

class AttributeSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const AttributeSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected == opt ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == opt ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                opt,
                style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected == opt ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}
