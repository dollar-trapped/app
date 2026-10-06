import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/gacha/widgets/batch_gacha_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _results = List.generate(
  10,
  (i) => CosmeticDraw(
    item: CosmeticItem(
      id: '$i',
      type: 'NAME_COLOR',
      name: '장식 $i',
      rarity: i == 2
          ? 'SPECIAL'
          : i == 1
          ? 'RARE'
          : 'COMMON',
      drawable: true,
      appearance: const {'nameColor': '#4477CC'},
    ),
    duplicate: false,
    chipsGranted: 0,
    ticketsAfter: 9 - i,
  ),
);

void main() {
  Widget scene({
    bool waiting = false,
    bool reduced = false,
    List<CosmeticDraw>? results,
    double textScale = 1,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(textScale),
      ),
      child: BatchGachaReveal(
        nickname: '달러',
        waiting: waiting,
        completed: 3,
        results: results ?? _results,
        child: const Scaffold(body: Text('결과 목록')),
      ),
    ),
  );

  Future<void> tapCard(WidgetTester tester, int index) async {
    final card = find.byKey(Key('batch-card-touch-$index'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  for (final reduced in [false, true]) {
    testWidgets('cards require 1/2/3 taps with reduced motion=$reduced', (
      tester,
    ) async {
      await tester.pumpWidget(scene(reduced: reduced));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('장식 0'), findsNothing);
      expect(find.text('결과 목록'), findsNothing);
      for (var index = 0; index < 3; index++) {
        for (var tap = 0; tap <= index; tap++) {
          expect(find.text('장식 $index'), findsNothing);
          await tapCard(tester, index);
        }
        expect(find.text('장식 $index'), findsOneWidget);
        await tapCard(tester, index); // Revealed cards stay revealed.
        expect(find.text('장식 $index'), findsOneWidget);
      }
      expect(find.text('장식 3'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'double taps during a turn count once and cards turn independently',
    (tester) async {
      await tester.pumpWidget(scene());
      await tester.tap(find.byKey(const Key('batch-card-touch-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('batch-card-touch-1')));
      await tester.tap(find.byKey(const Key('batch-card-touch-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final turn = tester
          .widget<Transform>(find.byKey(const Key('batch-card-turn-1')))
          .transform;
      expect(turn.storage[0], isNot(closeTo(1, .01)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('장식 0'), findsOneWidget);
      expect(find.text('장식 1'), findsNothing);
      await tapCard(tester, 1);
      expect(find.text('장식 1'), findsOneWidget);
    },
  );

  testWidgets('open all works while a card is turning', (tester) async {
    await tester.pumpWidget(scene());
    await tester.tap(find.byKey(const Key('batch-card-touch-2')));
    await tester.pump();
    await tester.ensureVisible(find.text('바로 열기'));
    await tester.tap(find.text('바로 열기'));
    await tester.pumpAndSettle();
    expect(find.text('결과 목록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waiting cannot reveal and completion retains the same scene', (
    tester,
  ) async {
    await tester.pumpWidget(scene(waiting: true));
    final state = tester.state(find.byType(BatchGachaReveal));
    await tapCard(tester, 0);
    expect(find.text('장식 0'), findsNothing);
    expect(find.text('바로 열기'), findsNothing);
    await tester.pumpWidget(scene());
    expect(tester.state(find.byType(BatchGachaReveal)), same(state));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('장식 0'), findsNothing);
    await tapCard(tester, 0);
    expect(find.text('장식 0'), findsOneWidget);
  });

  testWidgets('unknown outcomes cannot be opened', (tester) async {
    await tester.pumpWidget(scene(results: _results.take(3).toList()));
    await tapCard(tester, 3);
    expect(find.text('장식 3'), findsNothing);
    expect(find.text('카드를 눌러 열어보세요 · 0 / 10'), findsOneWidget);
  });

  testWidgets('all ten stay visible until result button is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(scene(reduced: true));
    for (var index = 0; index < 10; index++) {
      final count = index == 2
          ? 3
          : index == 1
          ? 2
          : 1;
      for (var tap = 0; tap < count; tap++) {
        await tapCard(tester, index);
      }
    }
    expect(find.text('결과 목록'), findsNothing);
    await tester.ensureVisible(find.text('결과 보기'));
    await tester.tap(find.text('결과 보기'));
    await tester.pump();
    expect(find.text('결과 목록'), findsOneWidget);
  });

  testWidgets('small screen with large text and reduced motion waiting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      scene(waiting: true, reduced: true, textScale: 1.5),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(scene(reduced: true, textScale: 1.5));
    await tapCard(tester, 0);
    expect(find.text('장식 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
