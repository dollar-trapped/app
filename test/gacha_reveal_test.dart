import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/widgets/gacha_reveal.dart';
import 'package:dollar_trapped/features/gacha/widgets/dollar_case_reveal.dart';

void main() {
  Widget scene({
    bool waiting = false,
    bool reduced = false,
    String rarity = 'SPECIAL',
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: GachaReveal(
        waitingForResult: waiting,
        rarity: rarity,
        child: const Scaffold(body: Text('결과')),
      ),
    ),
  );
  DollarCasePainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(find.byKey(const Key('dollar-case-scene')))
              .painter!
          as DollarCasePainter;
  for (final reduced in [false, true]) {
    testWidgets('single dollar lands before case tap, reduced=$reduced', (
      tester,
    ) async {
      await tester.pumpWidget(scene(reduced: reduced));
      expect(painter(tester).rarities, ['SPECIAL']);
      if (!reduced) {
        await tester.tap(find.byKey(const Key('gacha-case-touch')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(painter(tester).opening, 0);
        expect(painter(tester).drop, greaterThan(0));
      }
      await tester.pumpAndSettle();
      expect(painter(tester).drop, 1);
      expect(find.text('결과'), findsNothing);
      await tester.tap(find.byKey(const Key('gacha-case-touch')));
      await tester.pumpAndSettle();
      expect(find.text('결과'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'pending response cannot show rarity or be skipped; scene survives response',
    (tester) async {
      await tester.pumpWidget(scene(waiting: true));
      final state = tester.state(find.byType(DollarCaseReveal));
      await tester.tap(find.byKey(const Key('gacha-case-touch')));
      await tester.pump(const Duration(seconds: 10));
      expect(painter(tester).rarities, isEmpty);
      expect(find.text('바로 열기'), findsNothing);
      expect(find.text('결과'), findsNothing);
      await tester.pumpWidget(scene());
      expect(tester.state(find.byType(DollarCaseReveal)), same(state));
      await tester.pumpAndSettle();
      expect(painter(tester).drop, 1);
    },
  );
  testWidgets(
    'skip works during falling and repeated case taps do not restart opening',
    (tester) async {
      await tester.pumpWidget(scene());
      await tester.tap(find.text('바로 열기'));
      await tester.pump();
      expect(find.text('결과'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(scene());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gacha-case-touch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final progress = painter(tester).opening;
      await tester.tap(find.byKey(const Key('gacha-case-touch')));
      await tester.pump();
      expect(painter(tester).opening, progress);
      await tester.pumpAndSettle();
      expect(find.text('결과'), findsOneWidget);
    },
  );
  testWidgets('short phone large text and bottom navigation inset fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            padding: EdgeInsets.only(bottom: 48),
          ),
          child: const GachaReveal(child: Text('결과')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('gacha-case-touch')));
    await tester.pumpAndSettle();
    expect(find.text('결과'), findsOneWidget);
  });
}
