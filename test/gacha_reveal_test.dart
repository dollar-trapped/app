import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/widgets/gacha_reveal.dart';

void main() {
  Widget app({bool reduceMotion = false, VoidCallback? onResult}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: GachaReveal(
            child: Scaffold(
              body: TextButton(onPressed: onResult, child: const Text('결과 적용')),
            ),
          ),
        ),
      );

  testWidgets('reveals result automatically and enables its action', (
    tester,
  ) async {
    var applied = false;
    await tester.pumpWidget(app(onResult: () => applied = true));
    expect(find.text('결과 적용'), findsNothing);
    expect(find.text('연출 건너뛰기'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('연출 건너뛰기'), findsNothing);
    await tester.tap(find.text('결과 적용'));
    expect(applied, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skip opens result immediately', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('연출 건너뛰기'));
    await tester.pump();
    expect(find.text('결과 적용'), findsOneWidget);
    expect(find.text('연출 건너뛰기'), findsNothing);
  });

  testWidgets('reduced motion bypasses reveal', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    expect(find.text('결과 적용'), findsOneWidget);
    expect(find.text('연출 건너뛰기'), findsNothing);
  });

  testWidgets('fits a narrow screen and disposes during playback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
