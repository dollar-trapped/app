import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.all(24), child: content),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: actions,
            ),
          ],
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
    this.secondary = false,
  });
  final String label;
  final String hint;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: secondary
              ? AppColors.of(context).soft
              : AppColors.of(context).action,
          foregroundColor: secondary
              ? AppColors.of(context).forest
              : AppColors.of(context).background,
          disabledBackgroundColor: AppColors.of(context).surface,
          disabledForegroundColor: AppColors.of(context).muted,
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
        Text(hint, style: AppColors.of(context).caption),
      ],
    ],
  );
}
