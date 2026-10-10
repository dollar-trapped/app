import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/services/pending_draw_store.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = CosmeticItem(
  id: 'test',
  type: 'NAME_COLOR',
  name: '색상',
  rarity: 'COMMON',
  appearance: {'nameColor': '#4477CC'},
);

JsonMap _state(int count) => {
  'consecutiveCommonCount': count,
  'drawsUntilGuaranteed': 10 - count,
};
JsonMap _draw([int? count]) => {
  'cosmetic': {
    'id': 'test',
    'type': 'NAME_COLOR',
    'displayName': '색상',
    'rarity': 'COMMON',
    'appearance': {'nameColor': '#4477CC'},
  },
  'outcome': 'DUPLICATE',
  'dollarChipGranted': 1,
  'drawEntitlementCountAfter': 10,
  if (count != null) ..._state(count),
};

void main() {
  test('inventory and ordered draw snapshots parse server counters', () {
    final inventory = CosmeticInventory.fromJson({
      'items': [],
      'equipment': {'version': 1},
      'drawEntitlementCount': 20,
      'dollarChip': 0,
      ..._state(7),
    });
    expect(inventory.guaranteeState!.drawsUntilGuaranteed, 3);
    final counts = [8, 9, 0, 1, 2, 3, 4, 5, 6, 7];
    final batch = CosmeticBatchDraw.fromJson({
      'drawRequestId': 'batch',
      'count': 10,
      'results': counts.map(_draw).toList(),
      'drawEntitlementCountAfter': 10,
      'dollarChipBalanceAfter': 10,
      ..._state(7),
    });
    expect(batch.guaranteeState!.consecutiveCommonCount, 7);
    expect(
      batch.results.map((r) => r.guaranteeState!.consecutiveCommonCount),
      counts,
    );
    expect(batch.results[2].guaranteeState!.drawsUntilGuaranteed, 10);
  });

  test('historical responses retain unknown counters, never zero', () {
    expect(CosmeticDraw.fromJson(_draw()).guaranteeState, isNull);
    expect(
      CosmeticBatchDraw.fromJson({
        'drawRequestId': 'old',
        'count': 1,
        'results': [_draw()],
        'drawEntitlementCountAfter': 10,
        'dollarChipBalanceAfter': 0,
      }).guaranteeState,
      isNull,
    );
    expect(
      CosmeticInventory.fromJson({
        'items': [],
        'equipment': {'version': 1},
        'drawEntitlementCount': 20,
        'dollarChip': 0,
      }).guaranteeState,
      isNull,
    );
  });

  test('invalid or partial counter fields cannot promise a guarantee', () {
    for (final json in <JsonMap>[
      {'consecutiveCommonCount': 9},
      {'drawsUntilGuaranteed': 1},
      {..._state(9), 'drawsUntilGuaranteed': 10},
      _state(-1),
      _state(10),
      {'consecutiveCommonCount': '9', 'drawsUntilGuaranteed': 1},
    ]) {
      expect(CosmeticGuaranteeState.fromJson(json), isNull);
    }
  });

  test('catalog distinguishes cumulative, batch and absent policies', () {
    CosmeticCatalog catalog(JsonMap flags) => CosmeticCatalog.fromJson({
      'items': [],
      'drawPolicy': {
        'rarityProbabilityBps': {'COMMON': 7000, 'RARE': 2500, 'SPECIAL': 500},
        ...flags,
      },
    });
    final cumulative = catalog({
      'cumulativeGuaranteedRareOrAbove': true,
      'batchGuaranteedRareOrAbove': false,
    });
    expect(cumulative.cumulativeGuaranteedRareOrAbove, isTrue);
    expect(cumulative.batchGuaranteedRareOrAbove, isFalse);
    expect(
      catalog({'batchGuaranteedRareOrAbove': true}).batchGuaranteedRareOrAbove,
      isTrue,
    );
    expect(catalog({}).cumulativeGuaranteedRareOrAbove, isFalse);
    expect(catalog({}).batchGuaranteedRareOrAbove, isFalse);
  });

  for (final count in [0, 7, 9, null]) {
    testWidgets('cumulative display follows server count $count', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_Repo(count: count)));
      await tester.pumpAndSettle();
      final text = tester
          .widget<Text>(find.byKey(const Key('gacha-guarantee-status')))
          .data!;
      expect(
        text,
        count == null
            ? contains('확인하지 못했어요')
            : count == 9
            ? '누적 보장 9/10 · 다음 뽑기 레어 이상 확정'
            : '누적 보장 $count/10',
      );
      expect(find.textContaining('단뽑·10회 뽑기 누적 횟수 공유'), findsOneWidget);
      expect(find.textContaining('RARE 이상 1개 보장'), findsNothing);
    });
  }

  testWidgets('legacy policy keeps batch notice and hides cumulative count', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Repo(cumulative: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gacha-guarantee-status')), findsNothing);
    expect(find.textContaining('RARE 이상 1개 보장'), findsOneWidget);
  });

  for (final historical in [false, true]) {
    testWidgets(
      'replayed batch reloads current GET state (historical=$historical)',
      (tester) async {
        final repo = _Repo(historical: historical);
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('10회 뽑기'));
        await tester.tap(find.text('10회 뽑기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('바로 열기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('확인').last);
        await tester.pumpAndSettle();
        expect(repo.loads, greaterThanOrEqualTo(2));
        expect(find.text('누적 보장 2/10'), findsOneWidget);
      },
    );
    testWidgets(
      'replayed single draw reloads current GET state (historical=$historical)',
      (tester) async {
        final repo = _Repo(historical: historical);
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('1회 뽑기'));
        await tester.tap(find.text('1회 뽑기'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('gacha-case-touch')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('확인').last);
        await tester.tap(find.text('확인').last);
        await tester.pumpAndSettle();
        expect(repo.loads, greaterThanOrEqualTo(2));
        expect(find.text('누적 보장 2/10'), findsOneWidget);
        expect(find.textContaining('다음 뽑기 레어 이상 확정'), findsNothing);
      },
    );
  }
}

Widget _app(_Repo repo) => MaterialApp(
  home: LiveGachaPage(
    repository: repo,
    nickname: '테스트',
    pendingDrawStore: _Pending(),
    pendingBatchDrawStore: _Pending(),
    pendingExchangeStore: _Pending(),
  ),
);

class _Repo extends MockDollarRepository {
  _Repo({this.count = 7, this.cumulative = true, this.historical = false});
  int? count;
  final bool cumulative, historical;
  int loads = 0;
  @override
  Future<CosmeticCatalog> getCosmeticCatalog() async => CosmeticCatalog(
    items: [_item],
    probabilities: const {'COMMON': 7000, 'RARE': 2500, 'SPECIAL': 500},
    cumulativeGuaranteedRareOrAbove: cumulative,
    batchGuaranteedRareOrAbove: !cumulative,
  );
  @override
  Future<CosmeticInventory> getMyCosmetics() async {
    loads++;
    return CosmeticInventory(
      items: [_item],
      equipment: const CosmeticEquipment(version: 1),
      tickets: 20,
      dollarChips: 0,
      guaranteeState: count == null
          ? null
          : CosmeticGuaranteeState.fromJson(_state(count!)),
    );
  }

  @override
  Future<CosmeticDraw> drawCosmetic(String requestId) async {
    count = 2; // Current state advanced since this stored response was created.
    return CosmeticDraw.fromJson(_draw(historical ? null : 9));
  }

  @override
  Future<CosmeticBatchDraw> drawCosmeticBatch(String requestId) async {
    count = 2;
    return CosmeticBatchDraw.fromJson({
      'drawRequestId': requestId,
      'count': 10,
      'results': List.generate(10, (_) => _draw(historical ? null : 9)),
      'drawEntitlementCountAfter': 10,
      'dollarChipBalanceAfter': 10,
      if (!historical) ..._state(9),
    });
  }
}

class _Pending implements PendingDrawStore {
  String? value;
  @override
  Future<String?> read(String userId) async => value;
  @override
  Future<void> write(String userId, String requestId) async {
    value = requestId;
  }

  @override
  Future<void> clear(String userId) async {
    value = null;
  }
}
