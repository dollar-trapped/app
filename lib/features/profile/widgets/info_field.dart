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
          style: const TextStyle(
            color: Color(0xFF151916),
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
            style: const TextStyle(
              color: Color(0xFF151916),
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
              fillColor: Colors.white,
              constraints: const BoxConstraints.tightFor(height: 52),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE1E6E2)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF008A29)),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helper,
          style: const TextStyle(
            color: Color(0xFF667069),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
