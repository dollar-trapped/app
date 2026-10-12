import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';
import 'package:dollar_trapped/features/gacha/presentation/grade_config.dart';

GachaResult batch() => GachaResult(
  rewards: List.generate(
    10,
    (i) => GachaReward(
      id: '$i',
      grade: i == 3 ? GachaGrade.special : GachaGrade.common,
      title: 'item-$i',
    ),
  ),
);
void main() {
  testWidgets('last reward remains visible through afterglow', (tester) async {
    final result = GachaResult(
      rewards: const [
        GachaReward(id: '1', grade: GachaGrade.common, title: '유지되는 보상'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: GachaPresentation(result: result)),
    );
    final state = tester.state<GachaPresentationState>(
      find.byType(GachaPresentation),
    );
    state.controller.clock.value =
        (state.controller.timeline.cardsEnd + 200) /
        state.controller.timeline.totalMs;
    await tester.pump();
    final opacities = tester.widgetList<Opacity>(
      find.ancestor(of: find.text('유지되는 보상'), matching: find.byType(Opacity)),
    );
    expect(opacities, isNotEmpty);
    expect(opacities.every((widget) => widget.opacity == 1), isTrue);
    expect(find.text('확인'), findsNothing);
    state.controller.clock.value = 1;
    await tester.pump();
    expect(find.text('유지되는 보상'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });
  testWidgets(
    'batch automatically flips actual order then enables confirmation',
    (tester) async {
      final result = batch();
      await tester.pumpWidget(
        MaterialApp(home: GachaPresentation(result: result)),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      final tl = state.controller.timeline;
      for (var i = 0; i < 10; i++) {
        state.controller.clock.value = (tl.cardStarts[i] + 100) / tl.totalMs;
        await tester.pump();
        expect(find.byKey(ValueKey('gacha-card-$i')), findsOneWidget);
        expect(find.text('확인'), findsNothing);
      }
      state.controller.clock.value = 1;
      await tester.pump();
      expect(find.text('확인'), findsOneWidget);
      expect(state.controller.result, same(result));
      expect(
        state.controller.timeline.cardStarts[4] -
            state.controller.timeline.cardStarts[3],
        1500,
      );
      expect(find.byKey(const ValueKey('gacha-result-9')), findsOneWidget);
    },
  );
  testWidgets('skip at every phase keeps identical immutable results', (
    tester,
  ) async {
    for (final ms in [0, 800, 2401, 3350, 3800, 4500, 6500, 8000, 10000]) {
      final result = batch();
      await tester.pumpWidget(
        MaterialApp(
          home: GachaPresentation(key: UniqueKey(), result: result),
        ),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      state.controller.clock.value = ms / state.controller.timeline.totalMs;
      await tester.pump();
      await tester.tap(find.text('건너뛰기'));
      await tester.pump();
      expect(state.controller.result, same(result));
      expect(find.byKey(const ValueKey('gacha-result-9')), findsOneWidget);
      expect(state.controller.complete, isTrue);
    }
  });
  testWidgets('short phone large text keeps final controls usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
            padding: EdgeInsets.only(bottom: 48),
          ),
          child: GachaPresentation(result: batch(), quality: GachaQuality.low),
        ),
      ),
    );
    final state = tester.state<GachaPresentationState>(
      find.byType(GachaPresentation),
    );
    state.controller.clock.value = 8200 / state.controller.timeline.totalMs;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(find.text('확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('final reward actions are not intercepted by the skip surface', (
    tester,
  ) async {
    var applied = false, finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GachaPresentation(
          result: GachaResult(
            rewards: const [
              GachaReward(id: '1', grade: GachaGrade.common, title: 'item'),
            ],
          ),
          resultBuilder: (_) => TextButton(
            onPressed: () => applied = true,
            child: const Text('장착 테스트'),
          ),
          onFinish: () => finished = true,
        ),
      ),
    );
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    await tester.tap(find.text('장착 테스트'));
    expect(applied, isTrue);
    expect(finished, isFalse);
    await tester.tap(find.text('확인'));
    expect(finished, isTrue);
  });
}
