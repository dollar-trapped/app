import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/widgets/gacha_reveal.dart';

void main() {
  for (final reduced in [false, true]) {
    for (final entry in {'COMMON': 1, 'RARE': 1, 'SPECIAL': 1}.entries) {
      testWidgets(
        '${entry.key} waits for touch then reveals with one flip; disabled animations=$reduced',
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: reduced);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: GachaReveal(
                rarity: entry.key,
                child: const Scaffold(body: Text('결과')),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 20));
          expect(find.text('카드를 터치해서 열어보세요'), findsOneWidget);
          expect(find.text('결과'), findsNothing);
          await tester.tap(find.byKey(const Key('gacha-card-touch')));
          await tester.pump();
          if (!reduced) {
            await tester.pump(const Duration(milliseconds: 450));
            final transform = tester
                .widget<Transform>(find.byKey(const Key('gacha-card-turn')))
                .transform;
            expect(transform.storage[0], isNot(closeTo(1, .01)));
            expect(find.text('결과'), findsNothing);
          }
          await tester.pump(const Duration(milliseconds: 1600));
          await tester.pumpAndSettle();
          expect(find.text('결과'), findsOneWidget);
          expect(find.text('연출 건너뛰기'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'skip is available after touch and repeated taps do not restart',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GachaReveal(child: Text('결과'))),
      );
      expect(find.text('연출 건너뛰기'), findsNothing);
      await tester.tap(find.byKey(const Key('gacha-card-touch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(find.byKey(const Key('gacha-card-touch')));
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.text('결과'), findsOneWidget);
    },
  );

  testWidgets('skip reveals the result after an explicit touch', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GachaReveal(child: Text('결과'))),
    );
    await tester.tap(find.byKey(const Key('gacha-card-touch')));
    await tester.pump();
    await tester.tap(find.text('연출 건너뛰기'));
    await tester.pump();
    expect(find.text('결과'), findsOneWidget);
  });

  testWidgets('pending server response cannot be opened by tapping', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: GachaReveal(waitingForResult: true, child: Text('결과')),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('gacha-card-touch')));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('결과'), findsNothing);
    expect(find.text('뽑기 결과를 확인하고 있어요.'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
