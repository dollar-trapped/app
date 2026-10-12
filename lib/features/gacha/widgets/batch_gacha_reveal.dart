import 'package:flutter/material.dart';
import '../data/gacha_models.dart';
import '../presentation/gacha_result.dart';
import 'dollar_case_reveal.dart';

class BatchGachaReveal extends StatelessWidget {
  const BatchGachaReveal({
    super.key,
    required this.nickname,
    this.results = const [],
    this.waiting = false,
    this.completed = 0,
    this.child,
  });
  final String nickname;
  final List<CosmeticDraw> results;
  final bool waiting;
  final int completed;
  final Widget? child;
  @override
  Widget build(BuildContext context) => DollarCaseReveal(
    count: 10,
    waiting: waiting || results.length != 10,
    result: !waiting && results.length == 10
        ? GachaResult.fromDraws(results)
        : null,
    rarities: results.map((result) => result.item.rarity).toList(),
    child: child ?? const SizedBox.shrink(),
  );
}
