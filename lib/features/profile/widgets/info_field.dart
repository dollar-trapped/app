import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class InfoField extends StatelessWidget {
  const InfoField({
    super.key,
    required this.label,
    required this.controller,
    required this.helper,
    required this.onChanged,
    this.keyboardType,
    this.onInsertDecimal,
  });

  final String label;
  final TextEditingController controller;
  final String helper;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final VoidCallback? onInsertDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            cursorHeight: 24,
            style: TextStyle(
              color: AppColors.of(context).ink,
              fontSize: 15,
              height: 24 / 15,
            ),
            decoration: InputDecoration(
              suffixIcon: onInsertDecimal == null
                  ? null
                  : IconButton(
                      tooltip: '소수점 입력',
                      onPressed: onInsertDecimal,
                      icon: const Text('.', style: TextStyle(fontSize: 24)),
                    ),
              filled: true,
              fillColor: AppColors.of(context).background,
              constraints: const BoxConstraints.tightFor(height: 52),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.of(context).line),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.of(context).action),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helper,
          style: TextStyle(
            color: AppColors.of(context).muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
