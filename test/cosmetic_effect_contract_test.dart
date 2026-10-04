import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/cosmetics/preview/cosmetic_design_samples.dart';
import 'package:dollar_trapped/features/cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'server styleToken flows through catalog, inventory and draw result',
    () {
      final item = <String, dynamic>{
        'id': 'color_sunset',
        'type': 'NAME_COLOR',
        'displayName': '노을빛',
        'rarity': 'RARE',
        'isDrawable': true,
        'appearance': {
          'nameColor': null,
          'nameFont': null,
          'nameBackground': null,
          'styleToken': 'sunset_gradient',
        },
      };
      final catalog = CosmeticCatalog.fromJson({
        'items': [item],
        'drawPolicy': {
          'rarityProbabilityBps': {
            'COMMON': 7000,
            'RARE': 2500,
            'SPECIAL': 500,
          },
          'chipExchangeCost': 10,
        },
      });
      final inventory = CosmeticInventory.fromJson({
        'items': [
          {'cosmetic': item},
        ],
        'equipment': {
          'nameColorId': 'color_sunset',
          'nameFontId': null,
          'nameBackgroundId': null,
          'version': 1,
        },
        'drawEntitlementCount': 1,
        'dollarChip': 0,
      });
      final draw = CosmeticDraw.fromJson({
        'cosmetic': item,
        'outcome': 'NEW',
        'dollarChipGranted': 0,
        'drawEntitlementCountAfter': 0,
      });
      for (final parsed in [
        catalog.items.single,
        inventory.items.single,
        draw.item,
      ]) {
        expect(parsed.appearance['styleToken'], 'sunset_gradient');
        expect(parsed.appearance['nameColor'], isNull);
        expect(parsed.rarity, 'RARE');
      }
      expect(inventory.equipment.colorId, 'color_sunset');
      expect(catalog.probabilities, {
        'COMMON': 7000,
        'RARE': 2500,
        'SPECIAL': 500,
      });
    },
  );

  testWidgets('existing server scalar and null styleToken retain basic color', (
    tester,
  ) async {
    final item = CosmeticItem.fromJson({
      'id': 'old_blue',
      'type': 'NAME_COLOR',
      'displayName': '파랑',
      'rarity': 'COMMON',
      'isDrawable': true,
      'appearance': {
        'nameColor': '#4477CC',
        'nameFont': null,
        'nameBackground': null,
        'styleToken': null,
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerCosmeticNickname(nickname: '파랑', color: item),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('파랑')).style!.color,
      const Color(0xFF4477CC),
    );
    expect(find.byType(ShaderMask), findsNothing);
  });
  test('message snapshot keeps its rarity and separate effect token', () {
    final snapshot = MessageCosmetics.fromJson({
      'nameColor': {
        'id': 'color_sunset',
        'rarity': 'RARE',
        'color': null,
        'styleToken': 'sunset_gradient',
      },
      'nameBackground': {
        'id': 'old_gold',
        'rarity': 'SPECIAL',
        'background': 'gold_foil',
      },
    });
    expect(snapshot.color!.appearance['nameColor'], isNull);
    expect(snapshot.color!.appearance['styleToken'], 'sunset_gradient');
    expect(snapshot.color!.rarity, 'RARE');
    expect(snapshot.background!.rarity, 'SPECIAL');
    expect(snapshot.background!.appearance['nameBackground'], 'gold_foil');
  });

  test(
    'candidate deduplication compares token and slot, not nullable legacy color',
    () {
      final candidate = cosmeticDesignSamples.firstWhere(
        (e) => e.id == 'preview_sunset_gradient',
      );
      CosmeticItem registered(String token, String type) => CosmeticItem(
        id: 'server_id',
        type: type,
        name: '새 이름',
        rarity: 'RARE',
        appearance: {'nameColor': null, 'styleToken': token},
      );
      expect(
        sameCosmeticDesign(
          candidate,
          registered('sunset_gradient', 'NAME_COLOR'),
        ),
        isTrue,
      );
      expect(
        sameCosmeticDesign(
          candidate,
          registered('ocean_gradient', 'NAME_COLOR'),
        ),
        isFalse,
      );
      expect(
        sameCosmeticDesign(
          candidate,
          registered('sunset_gradient', 'NAME_BACKGROUND'),
        ),
        isFalse,
      );
    },
  );

  testWidgets('separate effect token renders while legacy color is null', (
    tester,
  ) async {
    final snapshot = MessageCosmetics.fromJson({
      'nameColor': {
        'color': null,
        'styleToken': 'sunset_gradient',
        'rarity': 'RARE',
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerCosmeticNickname(nickname: '노을', color: snapshot.color),
        ),
      ),
    );
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(snapshot.color!.appearance['nameColor'], isNull);
  });

  testWidgets(
    'unknown or wrong-slot effect falls back to complete basic nickname',
    (tester) async {
      for (final token in ['future_effect', 'sakura_drift']) {
        final color = CosmeticItem(
          id: 'future',
          type: 'NAME_COLOR',
          name: '',
          rarity: 'SPECIAL',
          appearance: {'nameColor': null, 'styleToken': token},
        );
        final bg = CosmeticItem(
          id: 'old',
          type: 'NAME_BACKGROUND',
          name: '',
          rarity: 'SPECIAL',
          appearance: {'nameBackground': 'gold_foil'},
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ServerCosmeticNickname(
                nickname: '기본',
                color: color,
                background: bg,
              ),
            ),
          ),
        );
        expect(
          tester.widget<Text>(find.text('기본')).style!.color,
          const Color(0xFF151916),
        );
        expect(find.byType(ShaderMask), findsNothing);
        expect(
          tester
              .widgetList<Container>(find.byType(Container))
              .where(
                (w) =>
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).color ==
                        const Color(0xFFF7EDA6),
              ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'style name in legacy nameColor is not interpreted as a new effect',
    (tester) async {
      const color = CosmeticItem(
        id: 'invalid',
        type: 'NAME_COLOR',
        name: '',
        rarity: 'RARE',
        appearance: {'nameColor': 'sunset_gradient'},
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServerCosmeticNickname(nickname: '기본', color: color),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsNothing);
      expect(
        tester.widget<Text>(find.text('기본')).style!.color,
        const Color(0xFF151916),
      );
    },
  );
}
