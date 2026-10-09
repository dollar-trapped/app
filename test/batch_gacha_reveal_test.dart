import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/gacha/widgets/batch_gacha_reveal.dart';
import 'package:dollar_trapped/features/gacha/widgets/dollar_case_reveal.dart';
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
      drawable: true,
      appearance: const {'nameColor': '#4477CC'},
    ),
    duplicate: false,
    chipsGranted: 0,
    ticketsAfter: 0,
  ),
);
void main() {
  Widget scene({bool waiting = false, bool reduced = false, int count = 10}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: BatchGachaReveal(
            nickname: '달러',
            waiting: waiting,
            results: results.take(count).toList(),
            child: const Scaffold(body: Text('10개 결과')),
          ),
        ),
      );
  DollarCasePainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(find.byKey(const Key('dollar-case-scene')))
              .painter!
          as DollarCasePainter;
  testWidgets(
    'ten dollars retain individual server rarities and case opens once',
    (tester) async {
      await tester.pumpWidget(scene());
      expect(painter(tester).count, 10);
      expect(
        painter(tester).rarities,
        results.map((r) => r.item.rarity).toList(),
      );
      await tester.pump(const Duration(milliseconds: 900));
      expect(painter(tester).drop, lessThan(1));
      expect(find.text('10개 결과'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('10 / 10'), findsOneWidget);
      await tester.tap(find.byKey(const Key('gacha-case-touch')));
      await tester.pumpAndSettle();
      expect(find.text('10개 결과'), findsOneWidget);
    },
  );
  testWidgets(
    'partial or pending responses never reveal an invented ten results',
    (tester) async {
      for (final pending in [false, true]) {
        await tester.pumpWidget(scene(waiting: pending, count: 3));
        await tester.pump(const Duration(seconds: 5));
        expect(painter(tester).rarities, isEmpty);
        expect(find.text('바로 열기'), findsNothing);
      }
    },
  );
  testWidgets(
    'reduced motion keeps case interaction and allows immediate skip',
    (tester) async {
      await tester.pumpWidget(scene(reduced: true));
      expect(find.text('10 / 10'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.text('바로 열기'));
      await tester.pump();
      expect(find.text('10개 결과'), findsOneWidget);
    },
  );
}
