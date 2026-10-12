import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/gacha/widgets/batch_gacha_reveal.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final results = List.generate(
  10,
  (i) => CosmeticDraw(
    item: CosmeticItem(
      id: '$i',
      type: 'NAME_COLOR',
      name: '장식 $i',
      rarity: i == 9
          ? 'SPECIAL'
          : i == 4
          ? 'RARE'
          : 'COMMON',
      appearance: const {},
    ),
    duplicate: false,
    chipsGranted: 0,
    ticketsAfter: 0,
  ),
);
void main() {
  Widget scene({int count = 10, bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: BatchGachaReveal(
        nickname: '달러',
        results: results.take(count).toList(),
        child: const Text('10개 결과'),
      ),
    ),
  );
  testWidgets('single case uses highest grade while keeping reward order', (
    tester,
  ) async {
    await tester.pumpWidget(scene());
    final result = tester
        .widget<GachaPresentation>(find.byType(GachaPresentation))
        .result;
    expect(result.highest, GachaGrade.special);
    expect(
      result.rewards.map((r) => r.grade),
      results.map((r) => GachaGrade.fromServer(r.item.rarity)),
    );
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(find.text('10개 결과'), findsOneWidget);
  });
  testWidgets('partial response cannot start ten-card presentation', (
    tester,
  ) async {
    await tester.pumpWidget(scene(count: 3));
    await tester.pump(const Duration(seconds: 20));
    expect(find.byType(GachaPresentation), findsNothing);
    expect(find.text('10개 결과'), findsNothing);
  });
  testWidgets('reduced motion directly presents all results', (tester) async {
    await tester.pumpWidget(scene(reduced: true));
    expect(find.text('10개 결과'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
