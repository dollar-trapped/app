import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/widgets/dollar_case_reveal.dart';

void main() {
  testWidgets('case remains locked during impact dust until 6.6 seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DollarCaseReveal(
          count: 10,
          rarities: List.filled(10, 'RARE'),
          rewardBuilder: (i) => Text('reward-$i'),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5700));
    await tester.tap(find.byKey(const Key('gacha-case-touch')));
    await tester.pump();
    expect(find.text('reward-0'), findsNothing);
    await tester.pump(const Duration(milliseconds: 920));
    expect(find.text('가방을 터치해서 열어보세요'), findsNothing);
    await tester.tap(find.byKey(const Key('gacha-case-touch')));
    await tester.pumpAndSettle();
    expect(find.text('reward-0'), findsOneWidget);
  });
  testWidgets('reward action wins over background dismissal', (tester) async {
    var applied = false, finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DollarCaseReveal(
          rarities: const ['COMMON'],
          rewardBuilder: (_) => TextButton(
            onPressed: () => applied = true,
            child: const Text('장착 테스트'),
          ),
          onFinish: () => finished = true,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.tap(find.text('바로 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장착 테스트'));
    await tester.pump();
    expect(applied, isTrue);
    expect(finished, isFalse);
    await tester.tapAt(const Offset(8, 120));
    expect(finished, isTrue);
  });
  for (final count in [1, 10]) {
    testWidgets(
      '$count rewards leave case individually without replacing scene',
      (tester) async {
        var finished = false;
        await tester.pumpWidget(
          MaterialApp(
            home: DollarCaseReveal(
              count: count,
              rarities: List.filled(count, 'RARE'),
              rewardBuilder: (i) => Text('item-$i'),
              onFinish: () => finished = true,
              child: const Text('old result page'),
            ),
          ),
        );
        final state = tester.state(find.byType(DollarCaseReveal));
        await tester.tap(find.byKey(const Key('gacha-case-touch')));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('item-0'), findsNothing);
        await tester.pumpAndSettle();
        for (var i = 0; i < count; i++) {
          await tester.tapAt(const Offset(8, 120));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 750));
          final growing = tester
              .widget<Transform>(find.byKey(const Key('case-reward-scale')))
              .transform
              .storage[0];
          expect(growing, greaterThan(.12));
          expect(growing, lessThan(1));
          await tester.tapAt(const Offset(8, 120));
          await tester.pump();
          expect(
            tester
                .widget<Transform>(find.byKey(const Key('case-reward-scale')))
                .transform
                .storage[0],
            1,
          );
          await tester.pumpAndSettle();
          expect(find.text('item-$i'), findsOneWidget);
          if (i > 0) expect(find.text('item-${i - 1}'), findsNothing);
          expect(find.text('old result page'), findsNothing);
          expect(tester.state(find.byType(DollarCaseReveal)), same(state));
        }
        expect(finished, isFalse);
        await tester.tapAt(const Offset(8, 120));
        expect(finished, isTrue);
      },
    );
  }
  testWidgets(
    'skip exposes all results in the same case scene on short phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.5),
              padding: EdgeInsets.only(bottom: 48),
            ),
            child: DollarCaseReveal(
              count: 10,
              rarities: List.filled(10, 'SPECIAL'),
              rewardBuilder: (i) =>
                  SizedBox(height: 150, child: Text('item-$i')),
              onFinish: () {},
              child: const Text('old result page'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('바로 열기'));
      await tester.pumpAndSettle();
      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-9'), findsOneWidget);
      expect(find.text('old result page'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
