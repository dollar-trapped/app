import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/widgets/gacha_reveal.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';

void main() {
  Widget scene({bool waiting = false, bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: GachaReveal(
        waitingForResult: waiting,
        rarity: 'SPECIAL',
        child: const Text('결과'),
      ),
    ),
  );
  testWidgets('pending response cannot begin presentation or invent a result', (
    tester,
  ) async {
    await tester.pumpWidget(scene(waiting: true));
    await tester.pump(const Duration(seconds: 12));
    expect(find.byType(GachaPresentation), findsNothing);
    expect(find.text('결과'), findsNothing);
    expect(find.text('건너뛰기'), findsNothing);
    await tester.pumpWidget(scene());
    expect(find.byType(GachaPresentation), findsOneWidget);
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(find.text('결과'), findsOneWidget);
  });
  for (final reduced in [false, true]) {
    testWidgets(
      'automatic reveal completes without a case tap, reduced=$reduced',
      (tester) async {
        await tester.pumpWidget(scene(reduced: reduced));
        if (!reduced) expect(find.text('결과'), findsNothing);
        await tester.pumpAndSettle();
        expect(find.text('결과'), findsOneWidget);
        expect(find.text('확인'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'background touch skips immediately but does not close the result',
    (tester) async {
      await tester.pumpWidget(scene());
      await tester.tapAt(const Offset(20, 220));
      await tester.pump();
      expect(find.text('결과'), findsOneWidget);
      await tester.tapAt(const Offset(20, 220));
      await tester.pump();
      expect(find.text('결과'), findsOneWidget);
    },
  );
}
