import 'package:flutter/material.dart';
import 'dollar_case_reveal.dart';

class GachaReveal extends StatelessWidget {
  const GachaReveal({
    super.key,
    required this.child,
    this.isPreview = false,
    this.waitingForResult = false,
    this.rarity = 'COMMON',
    this.preview,
  });
  final Widget child;
  final Widget? preview;
  final bool isPreview, waitingForResult;
  final String rarity;
  @override
  Widget build(BuildContext context) => DollarCaseReveal(
    rarities: waitingForResult ? const [] : [rarity],
    waiting: waitingForResult,
    preview: preview,
    child: child,
  );
}
