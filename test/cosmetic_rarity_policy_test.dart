import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/cosmetics/rendering/effect_registry.dart';
import 'package:dollar_trapped/features/cosmetics/rendering/cosmetic_motion.dart';
import 'package:dollar_trapped/features/cosmetics/widgets/server_cosmetic_preview.dart';

CosmeticItem item(
  String id,
  String rarity, {
  bool drawable = true,
  String type = 'NAME_COLOR',
  Map<String, dynamic> appearance = const {},
}) => CosmeticItem(
  id: id,
  name: id,
  type: type,
  rarity: rarity,
  drawable: drawable,
  appearance: appearance,
);

void main() {
  final reclassified = [
    for (var i = 0; i < 6; i++) item('common-$i', 'COMMON'),
    for (var i = 0; i < 3; i++) item('rare-$i', 'RARE'),
    for (var i = 0; i < 5; i++) item('special-$i', 'SPECIAL'),
    item('disabled', 'SPECIAL', drawable: false),
    item('future-slot', 'RARE', type: 'FUTURE_SLOT'),
  ];
  const probabilities = {'COMMON': 7000, 'RARE': 2500, 'SPECIAL': 500};
  test('reclassification gives 6/3/5 and preserves aggregate 70/25/5', () {
    final catalog = CosmeticCatalog(
      items: reclassified,
      probabilities: probabilities,
    );
    expect(catalog.drawableItems.length, 14);
    for (final entry in {'COMMON': 6, 'RARE': 3, 'SPECIAL': 5}.entries) {
      final group = catalog.drawableItems.where((i) => i.rarity == entry.key);
      expect(group.length, entry.value);
      expect(
        catalog.itemProbabilityPercent(group.first),
        closeTo(probabilities[entry.key]! / 100 / entry.value, .00000001),
      );
      expect(
        group.fold(0.0, (sum, i) => sum + catalog.itemProbabilityPercent(i)!),
        closeTo(probabilities[entry.key]! / 100, .00000001),
      );
    }
    expect(catalog.itemProbabilityPercent(reclassified.last), isNull);
    expect(catalog.itemProbabilityPercent(reclassified[14]), isNull);
  });
  test(
    'two static RARE additions produce 5% per RARE; unknown weighted policy is not guessed',
    () {
      final items = [
        ...reclassified,
        item('sunset', 'RARE'),
        item('mint', 'RARE'),
      ];
      final catalog = CosmeticCatalog(
        items: items,
        probabilities: probabilities,
      );
      expect(catalog.itemProbabilityPercent(items.last), 5);
      expect(
        CosmeticCatalog(
          items: items,
          probabilities: probabilities,
          withinRaritySelection: 'WEIGHTED',
        ).itemProbabilityPercent(items.last),
        isNull,
      );
    },
  );
  test('server policy selection and duplicate rewards are parsed', () {
    final catalog = CosmeticCatalog.fromJson({
      'items': [],
      'drawPolicy': {
        'rarityProbabilityBps': probabilities,
        'withinRaritySelection': 'WEIGHTED',
        'duplicateChipReward': {'common': 2, 'rare': 4, 'special': 6},
      },
    });
    expect(catalog.withinRaritySelection, 'WEIGHTED');
    expect(catalog.duplicateChipRewards, {
      'COMMON': 2,
      'RARE': 4,
      'SPECIAL': 6,
    });
  });
  for (final token in ['sunset_gradient', 'mint_lattice']) {
    testWidgets('$token is supported static RARE and fits small chat text', (
      tester,
    ) async {
      final isText = token == 'sunset_gradient';
      final cosmetic = item(
        token,
        'RARE',
        type: isText ? 'NAME_COLOR' : 'NAME_BACKGROUND',
        appearance: {'styleToken': token},
      );
      expect(CosmeticEffectRegistry.supports(cosmetic.type, token), isTrue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                child: ServerCosmeticNickname(
                  nickname: '달러물림',
                  size: 16,
                  color: isText ? cosmetic : null,
                  background: isText ? null : cosmetic,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CosmeticMotion), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  for (final token in [
    'golden_shimmer',
    'crimson_pulse',
    'gold_foil_shimmer',
  ]) {
    testWidgets('$token animates at 16px and stops with reduced motion', (
      tester,
    ) async {
      final bg = token == 'gold_foil_shimmer';
      final cosmetic = item(
        token,
        'SPECIAL',
        type: bg ? 'NAME_BACKGROUND' : 'NAME_COLOR',
        appearance: {'styleToken': token},
      );
      Widget app(bool reduced) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                child: ServerCosmeticNickname(
                  nickname: '달러물림',
                  size: 16,
                  color: bg ? null : cosmetic,
                  background: bg ? cosmetic : null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(CosmeticMotion), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(app(true));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('달러물림'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
