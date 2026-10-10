import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/cosmetics/rendering/cosmetic_motion.dart';
import 'package:dollar_trapped/features/cosmetics/rendering/effect_registry.dart';
import 'package:dollar_trapped/features/cosmetics/rendering/effects/cosmetic_text_painter.dart';
import 'package:dollar_trapped/features/cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:dollar_trapped/features/cosmetics/preview/cosmetic_expansion_preview_page.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const capture = Key('expansion-frame');
final fixture =
    jsonDecode(
          File('config/cosmetic_catalog_expansion.json').readAsStringSync(),
        )
        as Map<String, dynamic>;
final catalog = CosmeticCatalog.fromJson(fixture);
CosmeticItem byToken(String token) =>
    catalog.items.singleWhere((item) => item.appearance.values.contains(token));

Widget host(CosmeticItem item, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: capture,
          child: ServerCosmeticNickname(
            nickname: '달러물림',
            size: 16,
            color: item.type == 'NAME_COLOR' ? item : null,
            font: item.type == 'NAME_FONT' ? item : null,
            background: item.type == 'NAME_BACKGROUND' ? item : null,
          ),
        ),
      ),
    ),
  ),
);

Future<Uint8List> frame(WidgetTester tester, {String? saveAs}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(capture),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    if (saveAs != null) {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(saveAs).writeAsBytes(bytes!.buffer.asUint8List());
    }
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final result = Uint8List.fromList(data!.buffer.asUint8List());
    image.dispose();
    return result;
  }))!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in manifest) {
      final loader = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

  test(
    'proposed catalog has 30 unique supported items and uniform probabilities',
    () {
      expect(fixture.containsKey('catalogVersion'), isFalse);
      expect(catalog.items.length, 30);
      expect(catalog.items.map((item) => item.id).toSet().length, 30);
      for (final entry in {'COMMON': 9, 'RARE': 11, 'SPECIAL': 10}.entries) {
        final items = catalog.drawableItems.where(
          (item) => item.rarity == entry.key,
        );
        expect(items.length, entry.value);
        expect(
          items.fold<double>(
            0,
            (sum, item) => sum + catalog.itemProbabilityPercent(item)!,
          ),
          closeTo(catalog.probabilities[entry.key]! / 100, .000001),
        );
      }
      for (final item in catalog.items) {
        expect(
          item.appearance.values.where((value) => value != null).length,
          1,
        );
        if (item.type == 'NAME_FONT') {
          expect(
            CosmeticEffectRegistry.fonts.containsKey(
              item.appearance['nameFont'],
            ),
            isTrue,
          );
        } else if (item.appearance['styleToken'] != null) {
          expect(
            CosmeticEffectRegistry.supports(
              item.type,
              item.appearance['styleToken'],
            ),
            isTrue,
          );
        }
      }
      final crimson = catalog.items.singleWhere(
        (item) => item.id == 'cos_color_special_02',
      );
      expect(crimson.name, '핏빛 진홍');
      expect(crimson.rarity, 'SPECIAL');
      expect(crimson.appearance['styleToken'], 'blood_crimson');
      expect(
        CosmeticEffectRegistry.textEffects.containsKey('crimson_pulse'),
        isTrue,
      );
    },
  );

  test('hologram is green, briefly red, then green again', () {
    expect(CosmeticTextPainter.hologramRedMix(0), 0);
    expect(CosmeticTextPainter.hologramRedMix(.72), 1);
    expect(CosmeticTextPainter.hologramRedMix(.95), 0);
  });

  for (final token in [
    'blood_crimson',
    'unstable_hologram',
    'desert_tumbleweed',
  ]) {
    testWidgets(
      '$token visibly moves at chat size and reduced motion resets to a static frame',
      (tester) async {
        final item = byToken(token);
        await tester.pumpWidget(host(item));
        final start = await frame(tester);
        await tester.pump(
          Duration(milliseconds: token == 'unstable_hologram' ? 4320 : 1200),
        );
        expect(await frame(tester), isNot(orderedEquals(start)));
        await tester.pumpWidget(host(item, reduced: true));
        final stopped = await frame(tester);
        expect(stopped, orderedEquals(start));
        await tester.pump(const Duration(seconds: 6));
        expect(await frame(tester), orderedEquals(stopped));
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('달러물림'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final token in [
    'orange_solid',
    'banana_solid',
    'grape_solid',
    'broken_glass',
  ]) {
    testWidgets('$token is static and supports small chat labels', (
      tester,
    ) async {
      await tester.pumpWidget(host(byToken(token)));
      final start = await frame(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(await frame(tester), orderedEquals(start));
      expect(find.byType(CosmeticMotion), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('five bundled Korean fonts are distinct at 16px', (tester) async {
    final rendered = <Uint8List>[];
    for (final token in [
      'heavy_gothic',
      'future_square',
      'gentle_dodum',
      'playful_handwriting',
      'brush_script',
    ]) {
      await tester.pumpWidget(host(byToken(token)));
      rendered.add(await frame(tester));
      expect(find.byType(CosmeticMotion), findsNothing);
      expect(tester.takeException(), isNull);
    }
    expect(rendered.map(base64Encode).toSet().length, 5);
  });

  testWidgets(
    'development preview opens and displays the 30-item design fixture',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CosmeticExpansionPreviewPage()),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.textContaining('30종 디자인 시안'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNotNull,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all 30 previews fit; optionally export a visual contact sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: capture,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '달러물림 · 30종 장식 시안',
                      style: TextStyle(
                        fontFamily: 'Noto Sans KR',
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2.35,
                      children: [
                        for (final item in catalog.items)
                          Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F5F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.name} · ${item.rarity}',
                                  style: const TextStyle(
                                    fontFamily: 'Noto Sans KR',
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ServerCosmeticNickname(
                                  nickname: '달러물림',
                                  size: 20,
                                  color: item.type == 'NAME_COLOR'
                                      ? item
                                      : null,
                                  font: item.type == 'NAME_FONT' ? item : null,
                                  background: item.type == 'NAME_BACKGROUND'
                                      ? item
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
    final output = Platform.environment['COSMETIC_QA_OUTPUT'];
    if (output != null) {
      await frame(tester, saveAs: output);
    }
  });
}
