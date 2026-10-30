import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PeriodTab extends StatelessWidget {
  const PeriodTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected
              ? AppColors.of(context).action
              : AppColors.of(context).muted,
          backgroundColor: selected
              ? AppColors.of(context).soft
              : AppColors.of(context).background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
      ),
    );
  }
}
