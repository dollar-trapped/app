import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.color,
    required this.foreground,
    required this.onPressed,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback? onPressed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: AppColors.of(context).surface,
          disabledForegroundColor: AppColors.of(context).muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor == null
                ? BorderSide.none
                : BorderSide(color: borderColor!),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Noto Sans KR',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
