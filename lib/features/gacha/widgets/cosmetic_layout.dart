import 'package:flutter/material.dart';

import '../../profile/widgets/profile_layout.dart';

/// Keeps actions at the bottom on tall screens and scrollable on small screens.
class CosmeticContent extends StatelessWidget {
  const CosmeticContent({
    super.key,
    required this.content,
    required this.actions,
  });
  final Widget content;
  final Widget actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: const EdgeInsets.all(24), child: content),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: actions,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CosmeticAction extends StatelessWidget {
  const CosmeticAction({
    super.key,
    required this.label,
    required this.hint,
    this.onPressed,
  });
  final String label;
  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: ProfileStyle.action,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF5F7F5),
          disabledForegroundColor: ProfileStyle.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Noto Sans KR',
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
      if (hint.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(hint, style: ProfileStyle.caption),
      ],
    ],
  );
}
