import 'package:flutter/material.dart';

class AgreementRow extends StatelessWidget {
  const AgreementRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onView,
  });

  final VoidCallback onView;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: label,
              checked: value,
              onTap: () => onChanged(!value),
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: () => onChanged(!value),
                  borderRadius: BorderRadius.circular(4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(
                      children: [
                        IgnorePointer(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: value,
                              onChanged: (_) {},
                              activeColor: const Color(0xFF008A29),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(color: Color(0xFFE1E6E2)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 20 / 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              foregroundColor: const Color(0xFF667069),
            ),
            child: const Text(
              '보기',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
