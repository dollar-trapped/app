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
            obscureText: obscureText,
            style: const TextStyle(fontSize: 15, height: 1.6),
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: suffixIcon,
              hintStyle: const TextStyle(
                color: Color(0xFF667069),
                fontSize: 15,
                height: 1.6,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE1E6E2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF008A29)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorText ?? helperText,
          style: TextStyle(
            color: errorText == null
                ? const Color(0xFF667069)
                : const Color(0xFFB3261E),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
