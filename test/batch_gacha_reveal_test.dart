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
      rarity: i == 9 ? 'SPECIAL' : 'COMMON',
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

  testWidgets('ten cards enter, turn, reveal server items and then show list', (
    tester,
  ) async {
    await tester.pumpWidget(scene());
    expect(find.text('결과 목록'), findsNothing);
    expect(find.text('장식 0'), findsNothing);
    for (var i = 0; i < 10; i++) {
      expect(find.byKey(Key('batch-card-$i')), findsOneWidget);
    }
    await tester.pump(const Duration(milliseconds: 700));
    final turn = tester
        .widget<Transform>(find.byKey(const Key('batch-card-turn-0')))
        .transform;
    expect(turn.storage[0], isNot(closeTo(1, .01)));
    await tester.pump(const Duration(milliseconds: 4100));
    expect(find.text('장식 0'), findsOneWidget);
    expect(find.text('장식 9'), findsOneWidget);
    expect(find.text('결과 목록'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('결과 목록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'waiting cards rotate without exposing supplied outcomes or skip',
    (tester) async {
      await tester.pumpWidget(scene(waiting: true));
      await tester.pump(const Duration(milliseconds: 500));
      final turn = tester
          .widget<Transform>(find.byKey(const Key('batch-card-turn-0')))
          .transform;
      expect(turn.storage[0], isNot(closeTo(1, .01)));
      expect(find.text('장식 0'), findsNothing);
      expect(find.text('결과 목록'), findsNothing);
      expect(find.text('연출 건너뛰기'), findsNothing);
      expect(find.text('뽑기 결과를 확인하고 있어요. 3 / 10'), findsOneWidget);
    },
  );

  testWidgets('partial outcomes never invent the other seven rewards', (
    tester,
  ) async {
    await tester.pumpWidget(scene(results: _results.take(3).toList()));
    await tester.pump(const Duration(milliseconds: 5000));
    expect(find.text('장식 2'), findsOneWidget);
    expect(find.text('장식 3'), findsNothing);
    expect(find.text('미확인'), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen with large text reveals without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(scene(textScale: 1.5));
    await tester.pump(const Duration(milliseconds: 5000));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion shows results immediately and waiting stays static',
    (tester) async {
      await tester.pumpWidget(scene(reduced: true));
      expect(find.text('결과 목록'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(scene(waiting: true, reduced: true));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('결과 목록'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
