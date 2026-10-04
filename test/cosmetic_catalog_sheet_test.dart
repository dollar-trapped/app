import 'package:dollar_trapped/features/gacha/widgets/cosmetic_scene_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/widgets/cosmetic_catalog_sheet.dart';
import 'package:dollar_trapped/features/gacha/widgets/server_cosmetic_preview.dart';

CosmeticItem item(
  String id,
  String type,
  String style, {
  bool drawable = true,
}) => CosmeticItem(
  id: id,
  name: id,
  type: type,
  rarity: 'RARE',
  drawable: drawable,
  appearance: {type == 'NAME_COLOR' ? 'nameColor' : 'nameBackground': style},
);
void main() {
  testWidgets(
    'catalog filters previews without changing the per-item probability',
    (tester) async {
      final catalog = CosmeticCatalog(
        items: [
          item('노을빛', 'NAME_COLOR', 'sunset_gradient'),
          item('솜사탕', 'NAME_BACKGROUND', 'pastel_cloud'),
          item('지급 제외', 'NAME_COLOR', '#000000', drawable: false),
        ],
        probabilities: const {'RARE': 5000, 'SPECIAL': 5000},
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: CosmeticCatalogSheet(catalog: catalog, nickname: '달러'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('희귀 · 2종'), findsOneWidget);
      expect(find.text('50.00%'), findsNWidgets(2));
      final filter = find.widgetWithText(ChoiceChip, '글자색');
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('노을빛'));
      expect(find.text('솜사탕'), findsNothing);
      expect(find.text('지급 제외'), findsNothing);
      expect(find.text('개별 확률 25.0000%'), findsOneWidget);
      expect(find.byType(ShaderMask), findsWidgets);
    },
  );

  testWidgets('animated backgrounds move and respect reduced motion', (
    tester,
  ) async {
    final bg = item('오로라', 'NAME_BACKGROUND', 'aurora');
    Widget app(bool reduced) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: ServerCosmeticNickname(nickname: '달러', background: bg),
          ),
        ),
      ),
    );
    LinearGradient gradient() => tester
        .widgetList<Container>(find.byType(Container))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.gradient)
        .whereType<LinearGradient>()
        .first;
    await tester.pumpWidget(app(false));
    final before = gradient().begin;
    await tester.pump(const Duration(seconds: 1));
    expect(gradient().begin, isNot(before));
    await tester.pumpWidget(app(true));
    final stopped = gradient().begin;
    await tester.pump(const Duration(seconds: 1));
    expect(gradient().begin, stopped);
    expect(tester.takeException(), isNull);
  });

  for (final scene in CosmeticScenePainter.styles) {
    testWidgets(
      '$scene animates inside a narrow nickname and respects reduced motion',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Widget app(bool reduced) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: reduced,
              textScaler: const TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 220,
                  child: ServerCosmeticNickname(
                    nickname: '특별한 달러물림',
                    background: item(scene, 'NAME_BACKGROUND', scene),
                  ),
                ),
              ),
            ),
          ),
        );
        CosmeticScenePainter painter() => tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((widget) => widget.painter)
            .whereType<CosmeticScenePainter>()
            .first;
        await tester.pumpWidget(app(false));
        final before = painter();
        await tester.pump(const Duration(seconds: 1));
        expect(painter().shouldRepaint(before), isTrue);
        await tester.pumpWidget(app(true));
        final stopped = painter();
        await tester.pump(const Duration(seconds: 1));
        expect(painter().shouldRepaint(stopped), isFalse);
        expect(find.text('특별한 달러물림'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unknown style remains readable and compatible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerCosmeticNickname(
            nickname: '달러',
            color: item('unknown', 'NAME_COLOR', 'unknown_style'),
          ),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('달러')).style!.color,
      const Color(0xFF151916),
    );
    expect(tester.takeException(), isNull);
  });
}
