import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SignUpField extends StatelessWidget {
  const SignUpField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.helperText,
    required this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.errorText,
    this.suffixIcon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String helperText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final String? errorText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 15, height: 1.6),
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: suffixIcon,
              hintStyle: TextStyle(
                color: AppColors.of(context).muted,
                fontSize: 15,
                height: 1.6,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.of(context).line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.of(context).action),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorText ?? helperText,
          style: TextStyle(
            color: errorText == null
                ? AppColors.of(context).muted
                : AppColors.of(context).error,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
