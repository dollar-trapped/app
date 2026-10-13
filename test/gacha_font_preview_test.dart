import 'dart:convert';
import 'dart:io';

import 'package:dollar_trapped/features/cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/widgets/draw_session.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = CosmeticCatalog.fromJson(
    jsonDecode(
          File('config/cosmetic_catalog_expansion.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final fonts = catalog.items.where((item) => item.type == 'NAME_FONT');

  for (final count in [1, 10]) {
    testWidgets('all fonts are readable on $count-draw reveal cards', (
      tester,
    ) async {
      for (final font in fonts) {
        final draws = List.generate(
          count,
          (_) => CosmeticDraw(
            item: font,
            duplicate: false,
            chipsGranted: 0,
            ticketsAfter: 0,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: DrawSession<List<CosmeticDraw>>(
                key: ValueKey(font.id),
                nickname: '달러물림최강',
                batch: count == 10,
                request: () async => draws,
                results: (value) => value,
                repository: MockDollarRepository(),
              ),
            ),
          ),
        );
        await tester.pump();
        final presentation = tester.widget<GachaPresentation>(
          find.byType(GachaPresentation),
        );
        final builder = presentation.previewBuilder!;
        // Render the actual production preview builder independently of timing.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(builder: (context) => builder(context, count - 1)),
            ),
          ),
        );
        expect(
          tester.widget<Text>(find.text('달러물림최강')).style!.color,
          Colors.white,
          reason: font.name,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  testWidgets(
    'normal nickname and explicit color cosmetics retain their colors',
    (tester) async {
      final color = catalog.items.firstWhere(
        (item) =>
            item.type == 'NAME_COLOR' &&
            ServerCosmeticNickname.parseColor(item.appearance['nameColor']) !=
                null,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const ServerCosmeticNickname(nickname: '기본 글꼴'),
                ServerCosmeticNickname(
                  nickname: '색상 장식',
                  color: color,
                  defaultTextColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('기본 글꼴')).style!.color,
        const Color(0xFF151916),
      );
      expect(
        tester.widget<Text>(find.text('색상 장식')).style!.color,
        ServerCosmeticNickname.parseColor(color.appearance['nameColor']),
      );
    },
  );
}
