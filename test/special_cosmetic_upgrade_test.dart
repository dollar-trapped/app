import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/cosmetics/rendering/cosmetic_motion.dart';
import 'package:dollar_trapped/features/cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const captureKey = Key('nickname-frame');
CosmeticItem special(String slot, Map<String, dynamic> appearance) =>
    CosmeticItem(
      id: 'existing-item',
      type: slot,
      name: '기존 특별 장식',
      rarity: 'SPECIAL',
      appearance: appearance,
    );
Widget host({
  CosmeticItem? color,
  CosmeticItem? background,
  bool reduced = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: captureKey,
          child: ServerCosmeticNickname(
            nickname: '달러물림',
            color: color,
            background: background,
            size: 24,
          ),
        ),
      ),
    ),
  ),
);
Future<Uint8List> frame(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(captureKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = Uint8List.fromList(data!.buffer.asUint8List());
    image.dispose();
    return bytes;
  }))!;
}

void main() {
  testWidgets('past gold snapshot stays static without the new token', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        background: special('NAME_BACKGROUND', {'nameBackground': 'gold_foil'}),
      ),
    );
    final before = await frame(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(await frame(tester), orderedEquals(before));
    expect(find.byType(CosmeticMotion), findsNothing);
  });

  for (final token in [
    'gold_foil_shimmer',
    'golden_shimmer',
    'crimson_pulse',
  ]) {
    final isGold = token == 'gold_foil_shimmer';
    final item = special(isGold ? 'NAME_BACKGROUND' : 'NAME_COLOR', {
      if (isGold) 'nameBackground': null else 'nameColor': null,
      'styleToken': token,
    });
    Widget app(bool reduced) => host(
      color: isGold ? null : item,
      background: isGold ? item : null,
      reduced: reduced,
    );
    testWidgets('$token changes visibly, then freezes with reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(app(false));
      final before = await frame(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(await frame(tester), isNot(orderedEquals(before)));
      await tester.pumpWidget(app(true));
      final stopped = await frame(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(await frame(tester), orderedEquals(stopped));
      expect(item.id, 'existing-item');
      expect(item.rarity, 'SPECIAL');
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      '$token is static when reduced motion is enabled before opening',
      (tester) async {
        await tester.pumpWidget(app(true));
        final before = await frame(tester);
        await tester.pump(const Duration(seconds: 5));
        expect(await frame(tester), orderedEquals(before));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
